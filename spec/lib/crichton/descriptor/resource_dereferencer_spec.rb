require 'spec_helper'
require 'crichton/descriptor/resource_dereferencer'

module Crichton
  module Descriptor
    describe ResourceDereferencer do
      before(:all) do
        @resource_descriptor = '
id: DRDs
semantics:
  name:
    href: http://alps.io/schema.org/Text
idempotent:
  update:
    parameters:
      - href: name'
        @hash = YAML.load(@resource_descriptor)
      end

      let(:subject) { ResourceDereferencer.new(@hash) }

      describe '#initialize' do
        it 'returns the descriptor document passed to constructor' do
          expect(subject.resource_document).to eq(@hash)
        end

        it 'returns document id found in descriptor document' do
          expect(subject.resource_id).to eq('DRDs')
        end
      end

      describe '#resource_descriptors' do
        let(:resource_descriptors) { subject.resource_descriptors }

        it 'registers all available descriptor elements in the document' do
          expect(resource_descriptors.keys).to eq([ 'DRDs#name', 'DRDs#update' ])
        end

        it 'registers descriptors elements in registry' do
          expect(resource_descriptors.values.all? { |v| v.is_a?(Crichton::Descriptor::DescriptorElement) }).to be_true
        end
      end
    end
  end
end
