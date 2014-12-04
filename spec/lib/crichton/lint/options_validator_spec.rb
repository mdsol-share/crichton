require 'spec_helper'
require 'crichton/lint'

# TODO: Rewrite validation specs with a dynamically malleable descriptors doc instead of manipulating the hash

describe Crichton::Lint::OptionsValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, LINT_FILENAME) }

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    @descriptor = drds_descriptor
  end

  describe '#validate' do
    after do
      expect(validation_report(filename)).to eq(@errors || @warnings || @message)
    end
    
    it 'validates key names' do
      @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"bad_key" => 'value'}})
      @errors = expected_output(:error, 'descriptors.invalid_options_attribute', id: 'status', options_attr: 'bad_key',
        filename: filename, section: :descriptors, sub_header: :error) << 
        expected_output(:error, 'descriptors.invalid_options_attribute', id: 'status', options_attr: 'bad_key')
    end
    
    it 'validates there are no clashed key names' do
      @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"hash" => {}, 'list' => []}})
      @errors = expected_output(:error, 'descriptors.multiple_options', id: 'status', options_keys: 'hash, list',
        filename: filename, section: :descriptors, sub_header: :error) << 
        expected_output(:error, 'descriptors.multiple_options', id: 'status', options_keys: 'hash, list')
    end
    
    context '#external_option_check' do
    
      it 'validates that list options do not use hashes' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"list" => {'a' => 'b'}}})
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
          value_type: 'Hash', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
            value_type: 'Hash')
      end
            
      it 'validates that list options errors on string' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"list" => 'a'}})
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
          value_type: 'String', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
            value_type: 'String')
      end
    
      it 'validates that list options errors on fixnum' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"list" => 1}})
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
          value_type: 'Fixnum', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'list',
            value_type: 'Fixnum')
      end
    end
    
    context '#hash_option_check' do
    
      it 'validates that hash options do not use lists' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"hash" => ['a', 'b']}})
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'hash',
          value_type: 'list', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'hash',
            value_type: 'list')
      end
    
      it 'validates that hash options are not nil' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"hash" => nil}})
        @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'status', options_attr: 'hash', 
        filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'status', options_attr: 'hash')
      end
      
      it 'validates that hash options have non-nil values' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"hash" => {'a' => nil}}})
        @errors = expected_output(:warning, 'descriptors.missing_options_value', id: 'status', options_attr: 'hash', 
        filename: filename, section: :descriptors, sub_header: :warning) <<
          expected_output(:warning, 'descriptors.missing_options_value', id: 'status', options_attr: 'hash')
      end
    end
    
    context '#external_option_check' do
    
      it 'validates that external options are hashes' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"external" => ['a','b']}})
      
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'external', value_type: 'Array',
        filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'status', key_type: 'external', value_type: 'Array')
      end
      
      it 'validates that external options source is formatted correctly' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"external" => {'source' => []}}})
      
        @errors = expected_output(:error, 'descriptors.invalid_option_source_type', id: 'status', options_attr: 'external',
        filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_source_type', id: 'status', options_attr: 'external')
      end
      
      it 'validates that external options source has target and prompt in the source' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"external" => {'source' => 'http://crichton.example.com/drd_location_detail_list'}}})
      
        @errors = expected_output(:error, 'descriptors.missing_options_key', id: 'status', options_attr: 'external', child_name: 'target',
        filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.missing_options_key', id: 'status', options_attr: 'external', child_name: 'prompt') <<
          expected_output(:error, 'descriptors.missing_options_key', id: 'status', options_attr: 'external', child_name: 'target') <<
            expected_output(:error, 'descriptors.missing_options_key', id: 'status', options_attr: 'external', child_name: 'prompt')
      end
    end
    
    context '#href_option_check' do

      it 'validates valid local options href' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"id"=>"first_location"}})
        @descriptor['idempotent']['update']['data'][1].merge!({'options' => {"href" => "DRDs#first_location"}})
      
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end
    
      it 'validates valid http protocol in options href' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"href" => "http://github.com/mdsol/crichton"}})

        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end
    
      it 'reports an invalid non-local uri in options href' do
        @descriptor['idempotent']['update']['data'].first.merge!({'options' => {"id"=>"invalid_uri", "href" => "invalid_uri"}})
      
        @errors = expected_output(:error, 'descriptors.invalid_options_protocol', id: 'status', options_attr: 'href',
          uri: 'invalid_uri', filename: filename, section: :descriptors, sub_header: :error) << 
          expected_output(:error, 'descriptors.invalid_options_protocol', id: 'status',  options_attr: 'href',
            uri: 'invalid_uri')
      end
    
      it 'reports a malformed local reference in options href error' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {"id"=>"other_uri"}})
        @descriptor['idempotent']['update']['data'][1].merge!({'options' => {"id"=>"DRDs#local_uri#other_uri", "href" => "DRDs#local_uri#other_uri"}})
      
        @errors = expected_output(:warning, 'descriptors.invalid_options_ref', id: 'old_status', options_attr: 'href',
          ref: 'DRDs#local_uri#other_uri', filename: filename, section: :descriptors, sub_header: :warning) << 
          expected_output(:warning, 'descriptors.invalid_options_ref', id: 'old_status',  options_attr: 'href',
            ref: 'DRDs#local_uri#other_uri')        
      end
    
      it 'reports an invalid local option href error' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {'id' => 'DRDs#local_uri', "href" => "DRDs#local_uri"}})
      
        @errors = expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
          ref: 'DRDs#local_uri', type: 'option id', filename: filename, section: :descriptors, sub_header: :error) << 
          expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
            ref: 'DRDs#local_uri', type: 'option id')     
      end
    
      it 'reports a nonexistent id for local option href error' do
        @descriptor['idempotent']['update']['data'][0].merge!({'options' => {'id' => 'invalid_id#local_uri', "href" => "invalid_id#local_uri"}})

        @errors = expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
          ref: 'invalid_id#local_uri', type: 'descriptor', filename: filename, section: :descriptors, sub_header: :error) << 
          expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
            ref: 'invalid_id#local_uri', type: 'option id')  <<
          expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
            ref: 'invalid_id#local_uri', type: 'descriptor') <<
          expected_output(:error, 'descriptors.option_reference_not_found', id: 'status', options_attr: 'href',
            ref: 'invalid_id#local_uri', type: 'option id')
      end
    end
  end
end