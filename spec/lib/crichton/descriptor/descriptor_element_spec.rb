require 'spec_helper'
require 'crichton/descriptor/descriptor_element'

module Crichton
  module Descriptor
    describe DescriptorElement do
      let(:registry) do
        registry = mock('Registry')
        registry.stub('raw_descriptors').and_return(@raw_descriptors)
        registry.stub('get_external_deserialized_profile').and_return(@external_profile_registry)
        registry.stub('options_registry').and_return(@options_registry = {})
        registry
      end
      let(:subject) { DescriptorElement.new('DRDs', @descriptor_id, @descriptor_element ) }

      let(:dereferenced_hash) do
        subject.dereference(registry, dereferenced_hash = {}) do |h|
          dereferenced_hash.deep_merge!({ 'DRDs#name' => h })
        end
        dereferenced_hash
      end

      describe '#initialize' do
        before do
          @descriptor_id = 'name'
          @descriptor_element = { 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
          @raw_descriptors = { 'DRDs#name' => @descriptor_element }
          @external_profile_registry = {}
        end

        it 'returns document id as descriptor id if passed descriptor id is nil' do
          @descriptor_element = { 'id' => 'ID', 'doc' => 'The name of DRD', 'href' => 'http://alps.io/schema.org/Text' }
          @descriptor_id = nil
          expect(subject.descriptor_id).to eq('ID')
        end

        it 'returns empty hash if passed descriptor document is nil' do
          @descriptor_element = nil
          expect(subject.descriptor_document).to be_empty
        end

        it 'returns descriptor_element passed to constructor' do
          expect(subject.descriptor_document).to eq(@descriptor_element)
        end

        it 'returns descriptor id passed to constructor' do
          expect(subject.descriptor_id).to eq('name')
        end

        it 'returns document id passed to constructor' do
          expect(subject.document_id).to eq('DRDs')
        end
      end

      describe '#descriptor_options' do
        before(:all) do
          @descriptor_id = 'name'
        end

        it 'returns empty hash if no options found in descriptor element' do
          @descriptor_element = {}
          expect(subject.descriptor_options).to eq({})
        end

        it 'registers available options found in descriptor element' do
          @descriptor_element =
          { 'doc' => 'The name of DRD',
            'href' => 'http://alps.io/schema.org/Integer',
            'options' => { 'id' => 'name_list', 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options.keys).to eq([ 'DRDs#name_list' ])
        end

        it 'returns registered options found in descriptor element' do
          @descriptor_element =
          { 'doc' => 'The name of DRD',
            'href' => 'http://alps.io/schema.org/Integer',
            'options' => { 'id' => 'name_list', 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options['DRDs#name_list']).to eq({ 'id' => 'name_list', 'list' => ['samplename','drdname'] })
        end

        it 'returns empty hash if options doesnt have id' do
          @descriptor_element =
          { 'doc' => 'The name of DRD',
            'href' => 'http://alps.io/schema.org/Integer',
            'options' => { 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options).to eq({})
        end
      end

      describe '#dereference' do
        before do
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

          it 'uses local property values instead of dereferenced property values' do
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
          before do
            @descriptor_element = { 'doc' => 'The name of DRD', 'href' => 'alias' }
          end

          it 'returns additional properties from referenced descriptor' do
            @raw_descriptors = { 'DRDs#alias' => DescriptorElement.new('DRDs', 'alias', { 'field' => 'value' }) }
            expect(dereferenced_hash['DRDs#name']).to have_key('field')
          end

        end
      end
    end
  end
end
