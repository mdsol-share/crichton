require 'spec_helper'

module Crichton
  describe TransitionDescriptor do
    let(:transitions) { drds_descriptor['transitions']}
    let(:descriptor_document) { transitions['list'] }
    let(:resource_descriptor) { mock('resource_descriptor') }
    let(:descriptor) { TransitionDescriptor.new(resource_descriptor, descriptor_document, id: 'list') }

    describe '.new' do
      it 'returns a subclass of BaseDescriptor' do
        descriptor.should be_a(BaseDescriptor)
      end

      it_behaves_like 'a nested descriptor'
    end
    
    describe '#protocol_descriptor' do
      it 'returns a protocol description for the specified protocol' do
        transition_descriptor = mock('transition_descriptor')
        resource_descriptor.stub(:protocol_transition).with('http', 'list').and_return(transition_descriptor)
        descriptor.protocol_descriptor('http').should == transition_descriptor
      end
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
