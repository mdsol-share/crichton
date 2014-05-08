require 'spec_helper'
require 'crichton/descriptor/descriptor_element'

module Crichton
  module Descriptor
    describe DescriptorElement do
      let(:registry) do
        registry = double('Registry')
        registry.stub('raw_descriptors').and_return(@raw_descriptors)
        registry.stub('get_external_deserialized_profile').and_return(@external_profile_registry)
        registry.stub('options_registry').and_return(@options_registry = {})
        registry
      end
      let(:subject) { DescriptorElement.new('DRDs', @descriptor_id, @descriptor_element) }

      let(:dereferenced_hash) do
        subject.dereference(registry, @dereferenced_hash) do |h|
          @dereferenced_hash.deep_merge!({ 'DRDs#name' => h })
        end
        @dereferenced_hash
      end

      describe '#initialize' do
        before do
          @dereferenced_hash = {}
          @descriptor_id = 'name'
          @descriptor_element = { 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
          @raw_descriptors = { 'DRDs#name' => @descriptor_element }
          @external_profile_registry = {}
        end

        it 'sets document id as descriptor id if passed descriptor id is nil' do
          @descriptor_element = { 'id' => 'ID', 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
          @descriptor_id = nil
          expect(subject.descriptor_id).to eq('ID')
        end

        it 'sets empty hash if passed descriptor document is nil' do
          @descriptor_element = nil
          expect(subject.descriptor_document).to be_empty
        end

        it 'sets descriptor_element passed to constructor' do
          expect(subject.descriptor_document).to eq(@descriptor_element)
        end

        it 'sets descriptor id passed to constructor' do
          expect(subject.descriptor_id).to eq('name')
        end

        it 'sets document id passed to constructor' do
          expect(subject.document_id).to eq('DRDs')
        end
      end

      describe '#descriptor_options' do
        before(:all) do
          @dereferenced_hash = {}
          @descriptor_id = 'name'
        end

        it 'returns empty hash if no options found in descriptor element' do
          @descriptor_element = {}
          expect(subject.descriptor_options).to be_empty
        end

        it 'registers available options found in descriptor element' do
          @descriptor_element = {
              'doc' => 'The name of DRD',
              'href' => 'http://alps.io/schema.org/Integer',
              'options' => { 'id' => 'name_list', 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options.keys).to eq([ 'DRDs#name_list' ])
        end

        it 'returns registered options found in descriptor element' do
          @descriptor_element = {
              'doc' => 'The name of DRD',
              'href' => 'http://alps.io/schema.org/Integer',
              'options' => { 'id' => 'name_list', 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options['DRDs#name_list']).to eq({ 'id' => 'name_list', 'list' => ['samplename','drdname'] })
        end

        it 'returns empty hash if options does not have id' do
          @descriptor_element = {
              'doc' => 'The name of DRD',
              'href' => 'http://alps.io/schema.org/Integer',
              'options' => { 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options).to be_empty
        end
      end

      describe '#dereference' do
        before do
          @dereferenced_hash = {}
          @descriptor_id = 'name'
          @descriptor_element = { 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
          @raw_descriptors = { 'DRDs#name' => @descriptor_element }
          @external_profile_registry = {}
        end

        it 'returns the same hash if nothing to dereference' do
          expect(dereferenced_hash['DRDs#name']).to eq(registry.raw_descriptors['DRDs#name'])
        end

        context 'when dereferencing external href' do
          before do
            @external_profile_registry = { 'descriptors' => { 'Text' => { 'doc' => 'Simple text', 'field' => 'fieldvalue' } } }
          end

          it 'contains local property values instead of dereferenced property values' do
            @external_profile_registry = { 'descriptors' => { 'Text' => { 'doc' => 'Simple text' } } }
            expect(dereferenced_hash['DRDs#name']['doc']).to eq('The name of DRD')
          end

          it 'contains extra properties from dereferenced descriptors' do
            expect(dereferenced_hash['DRDs#name']).to have_key('field')
          end

          it 'contains correct property values from dereferenced descriptors' do
            expect(dereferenced_hash['DRDs#name']['field']).to eq('fieldvalue')
          end
        end

        context 'when dereferencing local href' do
          it 'contains additional properties from referenced descriptor' do
            @descriptor_element = { 'doc' => 'The name of DRD', 'href' => 'alias' }
            @raw_descriptors = { 'DRDs#alias' => DescriptorElement.new('DRDs', 'alias', { 'field' => 'value' }) }
            expect(dereferenced_hash['DRDs#name']).to have_key('field')
          end

          it 'contains dereferenced nested property' do
            @dereferenced_hash = { 'DRDs#other_name' => { 'doc' => 'Other name' } }
            @descriptor_element  = { 'doc' => 'The name of DRD', 'descriptors' => [{ 'href' => 'other_name' }] }
            expect(dereferenced_hash['DRDs#name']['descriptors']).to have_key('other_name')
          end

          it 'contains dereferenced nested property and valid value' do
            @dereferenced_hash = { 'DRDs#other_name' => { 'doc' => 'Other name' } }
            @descriptor_element  = { 'doc' => 'The name of DRD', 'descriptors' => [{ 'href' => 'other_name' }] }
            expect(dereferenced_hash['DRDs#name']['descriptors']['other_name']).to eq({'doc' => 'Other name'})
          end

          it 'contains local dereferenced nested value' do
            @descriptor_element  = { 'doc' => 'The name of DRD', 'href' => 'alias', 'descriptors' => [{ 'href' => 'other_name' }] }
            @dereferenced_hash = { 'DRDs#other_name' => { 'doc' => 'Other name' },
                                   'DRDs#alias' => { 'descriptors' => { 'other_name' => { 'doc' => 'Alias' } } } }
            expect(dereferenced_hash['DRDs#name']['descriptors']['other_name']).to eq({'doc' => 'Other name'})
          end

          it 'contains property from nested dereferenced descriptor' do
            @descriptor_element  = { 'doc' => 'The name of DRD', 'href' => 'alias', 'descriptors' => [{ 'href' => 'other_name' }] }
            @dereferenced_hash = { 'DRDs#other_name' => { 'doc' => 'Other name' },
                                   'DRDs#alias' => { 'descriptors' => { 'other_name' => { 'sample' => 'Alias' } } } }
            expect(dereferenced_hash['DRDs#name']['descriptors']['other_name']).to have_key('sample')
          end

          it 'contains nested dereferenced descriptor' do
            @descriptor_element  = { 'doc' => 'The name of DRD', 'href' => 'alias', 'descriptors' => [{ 'href' => 'other_name' }] }
            @dereferenced_hash = { 'DRDs#other_name' => { 'doc' => 'Other name' },
                                   'DRDs#alias' => { 'descriptors' => { 'last_name' => { 'sample' => 'Alias' } } } }
            expect(dereferenced_hash['DRDs#name']['descriptors']).to have_key('last_name')
          end
        end
      end
    end
  end
end
