require 'spec_helper'

module Crichton
  describe TransitionDescriptor do
    let(:transitions) { drds_descriptor['transitions']}
    let(:descriptor_document) { transitions[@rel || 'list'] }
    let(:descriptor) { TransitionDescriptor.new(mock('resource_descriptor'), descriptor_document, @options) }

    describe '.new' do
      it 'returns a subclass of BaseDescriptor' do
        descriptor.should be_a(BaseDescriptor)
      end

      it_behaves_like 'a nested descriptor'
    end

    describe '#rt' do
      it 'returns the descriptor return type' do
        descriptor.rt.should == descriptor_document['rt']
      end
    end

    describe '#type' do
      it 'returns the descriptor type' do
        descriptor.type.should == descriptor_document['type']
      end
    end
  end
end
