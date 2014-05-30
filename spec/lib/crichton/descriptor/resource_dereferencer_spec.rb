require 'spec_helper'
require 'crichton/descriptor/resource_dereferencer'

module Crichton
  module Descriptor
    describe ResourceDereferencer do
      before(:all) do
        @resource_descriptor = <<-DESCRIPTOR
          id: DRDs
          semantics:
            name: &name
              href: http://alps.io/schema.org/Text
          idempotent:
            update:
              parameters:
                - href: name
          extensions:
            _name:
              <<: *name
              field_type: text
        DESCRIPTOR
      end

      let(:hash) { YAML.load(@resource_descriptor) }
      let(:subject) { ResourceDereferencer.new(hash) }
      let(:dereferenced_document) { subject.dereference(@descriptors) }

      describe '#initialize' do
        it 'returns the descriptor document passed to constructor' do
          expect(subject.resource_document).to eq(hash)
        end

        it 'returns document id found in descriptor document' do
          expect(subject.resource_id).to eq('DRDs')
        end
      end

      describe '#resource_descriptors' do
        let(:resource_descriptors) { subject.resource_descriptors }

        it 'registers all available descriptor elements in the document' do
          expect(resource_descriptors.keys).to eq(%w(DRDs#name DRDs#update DRDs#_name))
        end

        it 'registers descriptor element in the document with valid content' do
          descriptor_element = resource_descriptors['DRDs#name']
          expected_result = { 'type' => 'semantic', 'href' => 'http://alps.io/schema.org/Text' }
          expect(descriptor_element.descriptor_document).to eq(expected_result)
        end

        it 'registers descriptors elements in registry' do
          expect(resource_descriptors.values.all? { |v| v.is_a?(Crichton::Descriptor::DescriptorElement) }).to be_true
        end
      end

      describe '#dereference' do
        before(:all) do
          hash = { 'type' => 'semantic', 'href' => 'href: http://alps.io/schema.org/Text' }
          @descriptors = {
            'DRDs#name' => hash,
            'DRDs#update' => { 'type' => 'unsafe', 'descriptors' => { 'name' => hash.merge({ 'scope' => 'uri' }) } }
          }
        end

        it 'returns valid document id' do
          expect(dereferenced_document['id']).to eq(hash['id'])
        end

        it 'returns valid dereferenced descriptor' do
          expect(dereferenced_document['descriptors']['name']).to eq(@descriptors['DRDs#name'])
        end

        it 'returns valid dereferenced descriptor with nested properties' do
          expect(dereferenced_document['descriptors']['update']).to eq(@descriptors['DRDs#update'])
        end

        it 'returns extensions after dereferencing' do
          expect(dereferenced_document['extensions'].any?).to be_true
        end
      end
    end
  end
end
