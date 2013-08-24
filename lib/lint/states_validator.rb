require 'yaml'
require 'crichton'
require 'lint/base_validator'

module Lint

  class StatesValidator < BaseValidator
    def initialize(registry)
      super( registry)
    end

    def validate
      #7, #8
     check_for_secondary_descriptor_keys

      #10, #11, #12, #13 check for the presence of required attributes for all transitions
      check_for_required_state_transition_properties
    end

    def check_for_secondary_descriptor_keys
      #7,8 Check for second level egregious errors
      secondary_descriptor_keys.each do |resource_type|
        add_to_errors('catastrophic.no_states', :resource => resource_type) if registry[resource_type].parent_descriptor.states.empty?
        add_to_errors('catastrophic.no_descriptors', :resource => resource_type)  if registry[resource_type].parent_descriptor.descriptors.empty?
      end
    end

    # core deep dive method looking for missing properties and other syntactical errors down to the transitions of the states: section
    def check_for_required_state_transition_properties
      # build a list of states for all secondary descriptors
      states = build_state_list()

      secondary_descriptor_keys.each do |resource_type|
        secondary_descriptor_states = get_states_for_secondary_descriptor(resource_type)
        if secondary_descriptor_states.empty?
          add_to_errors('states.no_transitions', :resource => resource_type)
        else
          secondary_descriptor_states.each do |state|
            curr_state= state[1]
            #16
            add_to_warnings('states.doc_property_missing', :resource => resource_type,
                          :state => curr_state.name) unless curr_state.doc

            # if a state does not have transitions, then check to see if it has a location property (e.g. deleted, error)
            if  curr_state.transitions.nil?
              add_to_warnings('states.location_property_missing', :resource => resource_type,
                            :state => curr_state.name) if curr_state.location.nil?
            else
              #
              # PUT INTO ITS OWN METHOD FOR TRANSITIONS CHECKING
              #
              curr_state.transitions.each do |transition|
                curr_transition = transition[1]
                #9
                add_to_errors('states.next_property_missing', :resource => resource_type,
                            :state => curr_state.name, :transition => curr_transition.name) if  curr_transition.next.nil?
                #10 Transition next property has no value
                add_to_errors(errors, 'states.empty_missing_next', :resource => resource_type,
                                           :state => curr_state.name, :transition => curr_transition.name)  if curr_transition.next && curr_transition.next.empty?
                #13 Transition conditions property has no value(s)
                add_to_errors('states.no_conditions_values', :resource => resource_type,
                              :state => curr_state.name, :transition => curr_transition.name) if curr_transition.empty_conditions_set
                #11
                check_for_phantom_state_transitions(states, resource_type, curr_state.name, curr_transition)
                #14
                add_to_warnings('states.no_self_property', :resource => resource_type,
                            :state => curr_state.name, :transition => curr_transition.id) if curr_transition.is_specified_name_property_not_self?
              end
            end
          end
        end
      end
    end

    # Build a comprehensive list of all states in order to test for transitions pointing to nowhere (#11)
    def build_state_list
      state_array = []
      secondary_descriptor_keys.each do |resource_type|
        get_states_for_secondary_descriptor(resource_type).each do |state|
          if state_array.include?(state)
            add_to_errors('states.duplicate_state', :resource => resource_type, :state => state)
          else
            state_array << state[0]
          end
        end
      end
      state_array
    end

    #ugly, gotta be a better way...
    def get_states_for_secondary_descriptor(secondary_descriptor)
      registry[secondary_descriptor].parent_descriptor.resource_descriptor.states[secondary_descriptor]
    end

      #11, check to see if any next transition maps to an existing state. Check for null values at every level.
    # No need to check if the next transition points to an external resource (e.g. 'location')
    def check_for_phantom_state_transitions states, secondary_descriptor, curr_state_name, curr_transition
      #
      # FIX THIS, STATES MAY BE AN ARRAY. MAYBE CHECK IF NOT A LOCATION INSTEAD
      #
      if curr_transition.next && curr_transition.is_next_a_string?
        add_to_errors('states.phantom_next_property', :secondary_descriptor => secondary_descriptor,
                      :state => curr_state_name,  :transition => curr_transition.name,
                      :next_state => curr_transition.next_state_name) unless states.include?(curr_transition.next_state_name)
      end
    end
  end
end
