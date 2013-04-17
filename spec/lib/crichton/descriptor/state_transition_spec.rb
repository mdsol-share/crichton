require 'spec_helper'

module Crichton
  module Descriptor
    describe StateTransition do
      let(:state_transitions) { drds_descriptor['states']['drds'].first['transitions'] }
      let(:state_transition_descriptor) do 
        state_transitions.detect { |descriptor| descriptor['id'] == 'create' }
      end
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor) { StateTransition.new(resource_descriptor, state_transition_descriptor) }
  
      describe '#conditions' do
        it 'returns the list of inclusion conditions for the transition' do
          descriptor.conditions.should == %w(can_create can_do_anything)
        end
      end
  
      describe '#next' do
        it 'returns the list of next states exposed by the transition' do
          descriptor.next.should == %w(activated error)
        end
      end
    end
  end
end
