require 'lint/base_validator'

module Lint
  class StatesValidator < BaseValidator

    def validate
      #7, #8
      check_for_secondary_descriptor_states

      #10, #11, #12, #13 check for the presence of required attributes for all transitions
      check_for_required_state_transition_properties
    end

    private

    def check_for_secondary_descriptor_states
      #7,8 Check for second level egregious errors
      resource_descriptor.states.each do |descriptor|
        add_error('catastrophic.no_states', resource: descriptor[0],
          filename: filename) if secondary_descriptor_states(descriptor).empty?
      end
    end


    # core deep dive method looking for missing properties and other syntactical
    # errors down to the transitions of the states: section
    def check_for_required_state_transition_properties
      # build a list of states for all secondary descriptors
      states_list = build_state_list

      resource_descriptor.states.each do |secondary_descriptor|
        secondary_descriptor_states(secondary_descriptor).each do |state|
          curr_state = state[1]
          options = {resource: secondary_descriptor[0], state: curr_state.name, filename: filename}
          #16
          add_warning('states.doc_property_missing', options) unless curr_state.doc

          # if a state does not have transitions, then check to see if it has a location property (e.g. deleted, error)
          if  curr_state.transitions.nil?
            add_warning('states.location_property_missing', options) if curr_state.location.nil?
          else
            check_resource_state_transitions(secondary_descriptor[0], curr_state, states_list)
          end
        end
      end
    end

    # Build a comprehensive list of all states in order to test for transitions pointing to nowhere (#11)
    def build_state_list
      state_array = []
      resource_descriptor.states.each do |secondary_descriptor|
        secondary_descriptor_states(secondary_descriptor).each do |state|
          if state_array.include?(state)
            add_error('states.duplicate_state', resource: secondary_descriptor[0],
              state: state, filename: filename)
          else
            state_array << state[0]
          end
        end
      end
      state_array
    end

    def check_resource_state_transitions(resource_name, curr_state, states_list)
      state_name = curr_state.name

      curr_state.transitions.each do |transition|
        curr_transition = transition[1]
        options = {resource: resource_name, state: state_name, transition: curr_transition.id,
          filename: filename}
        #9
        add_error('states.next_property_missing', options) unless curr_transition.next
        #10 Transition next property has no value
        add_error('states.empty_missing_next', options) if curr_transition.next && curr_transition.next.empty?
        #13 Transition conditions property has no value(s)
        add_error('states.no_conditions_values', options) if curr_transition.missing_condition_item?
        #11
        check_for_phantom_state_transitions(states_list, resource_name, state_name,
          curr_transition) if curr_transition.next
        #14
        add_warning('states.no_self_property', options) if curr_transition.is_specified_name_property_not_self?
      end
    end

    #11, check to see if any next transition maps to an existing state. Check for null values at every level.
    # No need to check if the next transition points to an external resource (e.g. 'location')
    def check_for_phantom_state_transitions(states_list, resource_name, curr_state_name, curr_transition)
      curr_transition.next.each do |next_state|
        add_error('states.phantom_next_property', secondary_descriptor: resource_name, state: curr_state_name,
          transition: curr_transition.name, next_state: next_state,
          filename: filename) unless valid_next_state(states_list,curr_transition, next_state)
      end
    end

    # Here we test if the next state of this transition exists in our pre-built list of all states
    # No need to test for next states that are external to this doc (e.g. having a location property)
    def valid_next_state(states_list, curr_transition, next_state)
      return  true if curr_transition.is_next_state_a_location?
      states_list.include?(next_state)
    end
  end
end
