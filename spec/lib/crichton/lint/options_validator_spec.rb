require 'spec_helper'
require 'crichton/lint'

# TODO: Rewrite validation specs with a dynamically malleable descriptors doc instead of manipulating the hash

describe Crichton::Lint::OptionsValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, @dest_filename) }

  before(:all) do
    @dest_filename = 'drds_lint.yml'
  end

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    @descriptor = drds_descriptor
  end

  describe '#validate' do
    after do
      expect(validation_report(filename)).to eq(@errors || @warnings || @message)
    end

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