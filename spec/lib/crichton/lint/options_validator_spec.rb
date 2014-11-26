require 'spec_helper'
require 'crichton/lint'

# TODO: Rewrite validation specs with a dynamically malleable descriptors doc instead of manipulating the hash

module Crichton
  module Lint
    describe OptionsValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) do
         create_drds_file(@descriptor, @dest_filename)
       end

      before(:all) do
        @dest_filename = 'drds_lint.yml'
      end

      before do
        allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
      end

      describe '#validate' do
        
        after do
          expect(validation_report).to eq(@errors || @warnings || @message)
        end

        def validation_report
          capture(:stdout) { validator.validate(filename) }
        end
        
        it 'validates valid local options href' do
          @descriptor = drds_descriptor.tap do |doc|
            doc['idempotent']['update']['data'][0].merge!({'options' => {"id"=>"first_location"}})
             doc['idempotent']['update']['data'][1].merge!({'options' => {"href" => "DRDs#first_location"}})
          end
          
          @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
        end
        
        it 'validates valid http protocol in options href' do
          @descriptor = drds_descriptor.tap do |doc|
            doc['idempotent']['update']['data'].first.merge!({'options' => {"href" => "http://github.com/mdsol/crichton"}})
          end
          
          @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
        end
        
        it 'reports an invalid non-local uri in options href' do
          @descriptor = drds_descriptor.tap do |doc|
            doc['idempotent']['update']['data'].first.merge!({'options' => {"id"=>"invalid_uri", "href" => "invalid_uri"}})
          end
          
          @errors = expected_output(:error, 'descriptors.invalid_options_protocol', id: 'status', options_attr: 'href',
            uri: 'invalid_uri', filename: filename, section: :descriptors, sub_header: :error) << 
            expected_output(:error, 'descriptors.invalid_options_protocol', id: 'status',  options_attr: 'href',
              uri: 'invalid_uri')
        end
        
        it 'reports a malformed local option href error' do
          @descriptor = drds_descriptor.tap do |doc|
            doc['idempotent']['update']['data'][0].merge!({'options' => {"id"=>"other_uri"}})
            doc['idempotent']['update']['data'][1].merge!({'options' => {"id"=>"DRDs#local_uri#other_uri", "href" => "DRDs#local_uri#other_uri"}})
          end
          
          @errors = expected_output(:warning, 'descriptors.invalid_options_ref', id: 'old_status', options_attr: 'href',
            ref: 'DRDs#local_uri#other_uri', filename: filename, section: :descriptors, sub_header: :warning) << 
            expected_output(:warning, 'descriptors.invalid_options_ref', id: 'old_status',  options_attr: 'href',
              ref: 'DRDs#local_uri#other_uri')        
        end
        
        it 'reports an invalid local option href error' do
          @descriptor = drds_descriptor.tap do |doc|
            doc['idempotent']['update']['data'][1].merge!({'options' => {'id' => 'DRDs#local_uri', "href" => "DRDs#local_uri"}})
          end
          
          @errors = expected_output(:error, 'descriptors.option_reference_not_found', id: 'old_status', options_attr: 'href',
            ref: 'DRDs#local_uri', type: 'option id', filename: filename, section: :descriptors, sub_header: :error) << 
            expected_output(:error, 'descriptors.option_reference_not_found', id: 'old_status', options_attr: 'href',
              ref: 'DRDs#local_uri', type: 'option id')     
        end
      end
    end
  end
end
