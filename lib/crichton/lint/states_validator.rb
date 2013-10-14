require 'crichton/lint/base_validator'

module Crichton
  module Lint
    class StatesValidator < BaseValidator

      def validate
        #7, #8
        check_for_secondary_descriptor_states

        #10, #11, #12, #13 check for the presence of required attributes for all transitions
        check_for_required_state_transition_properties

        check_transition_equivalence
      end

      private

      def check_for_secondary_descriptor_states
        #7,8 Check for second level egregious errors
        resource_descriptor.states.each do |secondary_descriptor_name, secondary_descriptor|
          if secondary_descriptor.empty?
            add_error('catastrophic.no_states', resource: secondary_descriptor_name)
          end
        end
      end


      # core deep dive method looking for missing properties and other syntactical
      # errors down to the transitions of the states: section
      def check_for_required_state_transition_properties
        # build a list of states for all secondary descriptors
        states_list = build_state_list

        resource_descriptor.states.each do |secondary_descriptor_name, secondary_descriptor|
          secondary_descriptor.each do |state_name, state|
            options = {resource: secondary_descriptor_name, state: state_name}
            #16
            add_warning('states.doc_property_missing', options) unless state.doc

            # if a state does not have transitions, then check to see if it has a location property (e.g. deleted, error)
            if  state.transitions.nil?
              add_warning('states.location_property_missing', options) if state.location.nil?
            else
              check_resource_state_transitions(secondary_descriptor_name, state, states_list)
            end
          end
        end
      end

      # Build a comprehensive list of all states in order to test for transitions pointing to nowhere (#11)
      def build_state_list
        state_array = []
        resource_descriptor.states.each do |secondary_descriptor_name, secondary_descriptor|
          secondary_descriptor.keys.each do |state_name|
            if state_array.include?(state_name)
              add_error('states.duplicate_state', resource: secondary_descriptor_name, state: state_name)
            else
              state_array << state_name
            end
          end
        end
        state_array
      end

      def check_resource_state_transitions(resource_name, curr_state, states_list)
        curr_state.transitions.values.each do |transition|
          options = {resource: resource_name, state: curr_state.name, transition: transition.id}
          #9
          add_error('states.next_property_missing', options) unless transition.next
          #10 Transition next property has no value
          add_error('states.empty_missing_next', options) if transition.next && transition.next.empty?
          #13 Transition conditions property has no value(s)
          add_error('states.no_conditions_values', options) if transition.missing_condition_item?
          #11
          check_for_phantom_state_transitions(states_list, resource_name, curr_state.name, transition) if transition.next
          #14
          add_warning('states.no_self_property', options) if transition.is_specified_name_property_not_self?
        end
      end

      #11, check to see if any next transition maps to an existing state. Check for null values at every level.
      # No need to check if the next transition points to an external resource (e.g. 'location')
      def check_for_phantom_state_transitions(states_list, resource_name, curr_state_name, curr_transition)
        curr_transition.next.each do |next_state|
          unless valid_next_state(states_list, curr_transition, next_state)
            add_error('states.phantom_next_property', secondary_descriptor: resource_name, state: curr_state_name,
              transition: curr_transition.name, next_state: next_state)
          end
        end
      end

      # Here we test if the next state of this transition exists in our pre-built list of all states
      # No need to test for next states that are external to this doc (e.g. having a location property)
      def valid_next_state(states_list, curr_transition, next_state)
        return true if curr_transition.is_next_state_a_location?
        states_list.include?(next_state)
      end

      #67, check for transitions missing from the states section that are found in the protocol and descriptor sections
      def check_transition_equivalence
        state_transitions = build_state_transition_list

        #first look for protocol transitions not found in the descriptor transitions
        build_descriptor_transition_list.each do |transition|
          unless state_transitions.include?(transition)
            add_error('states.descriptor_transition_not_found', transition: transition)
          end
        end

        # then check if there is a transition missing for any state transition specified in the states: section
        build_protocol_transition_list.each do |transition|
          unless state_transitions.include?(transition)
            add_error('states.protocol_transition_not_found', transition: transition)
          end
        end
      end
    end
  end
end
