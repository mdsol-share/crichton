require 'spec_helper'

module Crichton
  module Descriptor
    describe State do
      let(:state_descriptor) { drds_descriptor['states']['drds']['collection'] }
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor) { State.new(resource_descriptor, state_descriptor, 'collection') }
  
      describe '#doc' do
        it 'returns the underlying descriptor doc property' do
          descriptor.doc.should == state_descriptor['doc']
        end
      end
  
      describe '#id' do
        it 'returns the name of the state' do
          descriptor.id.should == 'collection'
        end
      end
      
      describe '#location' do
        it 'returns the location of the state in the state machine' do
          descriptor.location.should == state_descriptor['location']
        end
      end
      
      describe '#transitions' do
        it 'returns a hash of state transition descriptors' do
          descriptor.transitions['list'].should_not be_nil
        end
      end
    end
  end
end
