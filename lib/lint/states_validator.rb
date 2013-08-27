require 'yaml'
require 'crichton'
require 'lint/base_validator'

module Lint
  class StatesValidator < BaseValidator

    def validate
      #7, #8
      check_for_secondary_descriptor_states

      #10, #11, #12, #13 check for the presence of required attributes for all transitions
      check_for_required_state_transition_properties
    end

    def check_for_secondary_descriptor_states
      #7,8 Check for second level egregious errors
      @resource_descriptor.states.each do |descriptor|
        add_error('catastrophic.no_states', :resource => descriptor[0]) if secondary_descriptor_states(descriptor).empty?
      end

      @resource_descriptor.descriptors.each do |descriptor|
        add_error('catastrophic.no_descriptors', :resource => descriptor[0]) if descriptor.descriptors.empty?
      end
    end

    def secondary_descriptor_states(descriptor)
      descriptor[1]
    end

    # core deep dive method looking for missing properties and other syntactical errors down to the transitions of the states: section
    def check_for_required_state_transition_properties
      # build a list of states for all secondary descriptors
      states_list = build_state_list

      @resource_descriptor.states.each do |secondary_descriptor|
        secondary_descriptor_states(secondary_descriptor).each do |state|
          curr_state = state[1]
          #16
          add_warning('states.doc_property_missing', :resource => secondary_descriptor[0],
                      :state => curr_state.name) unless curr_state.doc

          # if a state does not have transitions, then check to see if it has a location property (e.g. deleted, error)
          if  curr_state.transitions.nil?
            add_warning('states.location_property_missing', :resource => secondary_descriptor[0],
                        :state => curr_state.name) if curr_state.location.nil?
          else
            check_resource_state_transitions(secondary_descriptor[0], curr_state, states_list)
          end
        end
      end
    end

    # Build a comprehensive list of all states in order to test for transitions pointing to nowhere (#11)
    def build_state_list
      state_array = []
      @resource_descriptor.states.each do |secondary_descriptor|
        secondary_descriptor_states(secondary_descriptor).each do |state|
          if state_array.include?(state)
            add_error('states.duplicate_state', :resource => secondary_descriptor[0], :state => state)
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
        #9
        add_error('states.next_property_missing', :resource => resource_name, :state => state_name, :transition => curr_transition.name) if  curr_transition.next.nil?
        #10 Transition next property has no value
        add_error('states.empty_missing_next', :resource => resource_name, :state => state_name,
                  :transition => curr_transition.name) if curr_transition.next && curr_transition.next.empty?
        #13 Transition conditions property has no value(s)
        add_error('states.no_conditions_values', :resource => resource_name, :state => state_name,
                  :transition => curr_transition.name) if curr_transition.empty_conditions_set
        #11
        check_for_phantom_state_transitions(states_list, resource_name, state_name, curr_transition)
        #14
        add_warning('states.no_self_property', :resource => resource_name, :state => state_name,
                    :transition => curr_transition.id) if curr_transition.is_specified_name_property_not_self?
      end
    end


    #11, check to see if any next transition maps to an existing state. Check for null values at every level.
    # No need to check if the next transition points to an external resource (e.g. 'location')
    def check_for_phantom_state_transitions states_list, resource_name, curr_state_name, curr_transition
      #
      # TODO: STATES MAY BE AN ARRAY. MAYBE CHECK IF NOT A LOCATION INSTEAD
      #
      if curr_transition.next && curr_transition.is_next_a_string?
        add_error('states.phantom_next_property', :secondary_descriptor => resource_name,
                  :state => curr_state_name, :transition => curr_transition.name,
                  :next_state => curr_transition.next_state_name) unless states_list.include?(curr_transition.next_state_name)
      end
    end
  end
end
