require 'spec_helper'

module Crichton
  describe SemanticDescriptor do
    let(:descriptor_document) { drds_descriptor }
    let(:descriptor) { SemanticDescriptor.new(mock('resource_descriptor'), descriptor_document) }

    describe '.new' do
      it 'returns a subclass of BaseDescriptor' do
        descriptor.should be_a(BaseDescriptor)
      end

      it_behaves_like 'a nested descriptor'
    end

    describe '#sample' do
      it 'returns a sample value for the descriptor' do
        descriptor.sample.should == descriptor_document['sample']
      end
    end

    describe '#type' do
      it 'returns semantic' do
        descriptor.type.should == 'semantic'
      end
    end
  end
end
