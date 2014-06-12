require 'spec_helper'
require 'crichton/descriptor/descriptor_element'

module Crichton
  module Descriptor
    describe DescriptorElement do
      let(:registry) do
        registry = double('Registry')
        allow(registry).to receive('raw_descriptors').and_return(raw_descriptors)
        allow(registry).to receive('options_registry').and_return(options)
        allow(registry).to receive('external_profile_dereference').and_return(external_dereference)
        registry
      end

      let(:options) { { 'DRDs#names' => { 'id' => 'names', 'list' => [ 'samplename', 'drdname' ] } } }
      let(:raw_descriptors) do
        {
            'DRDs#name' => DescriptorElement.new('DRDs', 'name', { 'type' => 'semantic' }),
            'DRDs#update' => DescriptorElement.new('DRDs', 'update', {
                'type' => 'idempotent', 'doc' => 'update transition',
                'descriptors' => [{ 'href' => 'name', 'ext' => '_update_name' }]
            }),
            'DRDs#create' => DescriptorElement.new('DRDs', 'create', {
                'type' => 'unsafe', 'href' => @update,
                'descriptors' => [{ 'href' => (@name || 'name'), 'ext' => '_create_name' }]
            }),
            'DRDs#_create_name' => DescriptorElement.new('DRDs', '_create_name', {
                'doc' => 'Create name', 'field_type' => 'text',
                'options' => { 'href' => 'DRDs#names' }
            }),
            'DRDs#_update_name' => DescriptorElement.new('DRDs', '_update_name', {
                'doc' => 'Update name', 'sample' => 'samplename',
                'options' => { 'id' => 'names', 'list' => [ 'samplename', 'drdname' ] }
            }),
            'DRDs#_size' => DescriptorElement.new('DRDs', '_size', {
                'doc' => 'Size of the DRD', 'options' => { 'list' => [ 'small', 'large' ] }
            })
        }
      end

      let(:external_dereference) do
        {
          'type' => 'idempotent', 'doc' => 'update transition',
          'descriptors' => {
              'name' => {
                  'type' => 'semantic', 'doc' => 'Update name', 'sample' => 'samplename',
                  'options' => { 'id' => 'names', 'list' => [ 'samplename', 'drdname' ] }
              }
          }
        }
      end

      let(:options_registry) do
        raw_descriptors.each_with_object({}) { |(_, descriptor_element), hash| hash.merge!(descriptor_element.descriptor_options) }
      end

      let(:dereferenced_hash) do
        raw_descriptors.each_with_object({}) do |(k, descriptor_element), dereferenced_hash|
          descriptor_element.dereference(registry, dereferenced_hash) do |h|
            dereferenced_hash.merge!({ k => h })
          end
        end
      end

      let(:subject) { DescriptorElement.new(@document_id, @descriptor_id, @document) }

      describe '#initialize' do
        before(:all) do
          @document = { 'id' => 'ID', 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
        end

        it 'sets document id as descriptor id if passed descriptor id is nil' do
          @descriptor_id = nil
          @document_id = nil
          expect(subject.descriptor_id).to eq('ID')
        end

        it 'sets empty hash if passed descriptor document is nil' do
          @document = nil
          expect(subject.descriptor_document).to be_empty
        end

        it 'sets descriptor_element passed to constructor' do
          expect(subject.descriptor_document).to eq(@document)
        end

        it 'sets descriptor id passed to constructor' do
          @descriptor_id = 'name'
          expect(subject.descriptor_id).to eq('name')
        end

        it 'sets document id passed to constructor' do
          @document_id = 'DRDs'
          expect(subject.document_id).to eq('DRDs')
        end
      end

      describe '#descriptor_options' do
        it 'returns empty hash if no options found in descriptor element' do
          expect(raw_descriptors['DRDs#name'].descriptor_options).to be_empty
        end

        it 'registers available options found in descriptor element' do
          expected = { 'DRDs#names' => { 'id' => 'names', 'list' => [ 'samplename', 'drdname' ] } }
          expect(raw_descriptors['DRDs#_update_name'].descriptor_options).to eq(expected)
        end

        it 'returns empty hash if options does not have id' do
          expect(raw_descriptors['DRDs#_size'].descriptor_options).to be_empty
        end

        it 'returns correctly dereferenced options' do
          expect(options_registry).to eq(options)
        end
      end

      describe '#dereference' do
        it 'returns the same hash if nothing to dereference' do
          expect(dereferenced_hash['DRDs#name']).to eq(raw_descriptors['DRDs#name'].descriptor_document)
        end

        share_examples_for 'dereferencing href' do
          it 'contains additional properties from dereferenced descriptor' do
            expect(dereferenced_hash['DRDs#create']).to have_key('doc')
          end

          it 'contains additional properties from dereferenced descriptor and value is valid' do
            expect(dereferenced_hash['DRDs#create']['doc']).to eq('update transition')
          end

          it 'contains correct values which are not overridden after dereferencing' do
            expect(dereferenced_hash['DRDs#create']['type']).to eq('unsafe')
          end

          it 'contains dereferenced nested property' do
            expect(dereferenced_hash['DRDs#create']['descriptors']).to have_key('name')
          end

          it 'contains extensions dereferenced nested property' do
            expect(dereferenced_hash['DRDs#create']['descriptors']['name']).to have_key('field_type')
          end

          it 'contains property from nested dereferenced descriptor' do
            expect(dereferenced_hash['DRDs#create']['descriptors']['name']).to have_key('sample')
          end

          it 'contains original property value of nested descriptor after dereferencing' do
            expect(dereferenced_hash['DRDs#create']['descriptors']['name']['doc']).to eq('Create name')
          end

          it 'contains correctly dereferenced descriptor' do
            expected_result = {
                'type' => 'unsafe',
                'doc' => 'update transition',
                'href' => @update,
                'descriptors' => {
                    'name' => {
                        'type' => 'semantic',
                        'doc' => 'Create name',
                        'field_type' => 'text',
                        'sample' => 'samplename',
                        'options' => {
                            'id' => 'names',
                            'list' => [ 'samplename', 'drdname' ]
                        }
                    }
                }
            }
            expect(dereferenced_hash['DRDs#create']).to eq(expected_result)
          end
        end

        context 'when dereferencing local href' do
          before(:all) do
            @update = 'update'
          end

          it_behaves_like 'dereferencing href'

          it 'raises an error when no local descriptor is not found' do
            @name = 'name2'
            expect{ dereferenced_hash }.to raise_error(Crichton::DescriptorNotFoundError,
              /No descriptor element 'name2' has been found in 'DRDs' descriptor document.*/)
          end
        end

        context 'when dereferencing external href' do
          before(:all) do
            @update = 'http://example.org/Something'
          end

          it_behaves_like 'dereferencing href'
        end
      end
    end
  end
end
