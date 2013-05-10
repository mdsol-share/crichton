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
      
      describe '#available?' do
        context 'without :conditions option' do
          it 'always returns true' do
            state_transition_descriptor.delete('conditions')
            descriptor.should be_available
          end
        end
        
        context 'with :conditions option' do
          context 'with a string for a state transition condition' do
            it 'returns true with a matching string option' do
              descriptor.should be_available({conditions: 'can_create'})
            end
  
            it 'returns true with a matching symbol option' do
              descriptor.should be_available({conditions: :can_create})
            end
  
            it 'returns false without a matching string option' do
              descriptor.should_not be_available({conditions: 'can_do_something'})
            end
  
            it 'returns false without a matching symbol option' do
              descriptor.should_not be_available({conditions: :can_do_something})
            end
          end
          
          context 'with a hash for a state transition condition' do
            before do
              state_transition_descriptor['conditions'] = [{'can_create' => 'object'}]
            end

            it 'returns true with a matching hash option' do
              descriptor.should be_available({conditions: {can_create: :object}})
            end

            it 'returns false without a matching hash option' do
              descriptor.should_not be_available({conditions: {can_create: 'other_object'}})
            end

            it 'returns false with any string option' do
              descriptor.should_not be_available({conditions: 'can_create'})
            end

            it 'returns false with any symbol option' do
              descriptor.should_not be_available({conditions: :can_create})
            end
          end
        end
      end
  
      describe '#conditions' do
        it 'returns the list of inclusion conditions for the transition' do
          descriptor.conditions.should == %w(can_create can_do_anything)
        end
        
        it 'returns an empty hash when there are no conditions specified' do
          state_transition_descriptor.delete('conditions')
          descriptor.conditions.should be_empty
        end
      end
  
      describe '#next' do
        it 'returns the list of next states exposed by the transition' do
          descriptor.next.should == %w(activated error)
        end

        it 'returns an empty hash when there are no next states specified' do
          state_transition_descriptor.delete('next')
          descriptor.next.should be_empty
        end
      end
    end
  end
end
