require 'spec_helper'

module Crichton
  describe TransitionDescriptor do
    let(:transitions) { drds_descriptor['transitions']}
    let(:descriptor_document) { transitions[@rel || 'list'] }
    let(:descriptor) { TransitionDescriptor.new(descriptor_document, @options) }

    describe '#rt' do
      it 'returns the descriptor return type' do
        descriptor.rt.should == descriptor_document['rt']
      end
    end

    describe '#type' do
      it 'returns the descriptor return type' do
        descriptor.type.should == descriptor_document['type']
      end
    end
  end
end
