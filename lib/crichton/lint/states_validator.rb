require 'crichton/lint/base_validator'

module Crichton
  module Lint
    # class to lint validate the states section of a resource descriptor document
    class StatesValidator < BaseValidator
      section :states

      # standard lint validate method
      def validate
        #7, #8
        check_for_secondary_descriptor_states

        #10, #11, #12, #13 check for the presence of required attributes for all transitions
        check_for_required_state_transition_properties

        check_transition_equivalence

        # check that there is one and only one name:self property on transition per state
        check_state_transition_names

        check_for_duplicate_transition_names
      end

      private

      def check_state_transition_names
        resource_descriptor.states.each do |secondary_descriptor_name, secondary_descriptor|
          secondary_descriptor.each do |state_descriptor_name, state_descriptor|
            transitions = state_descriptor.transitions
            unless transitions.empty? || transitions.values.one? { |st| (name = st.descriptor_document['name']) && name == 'self' }
              add_error('states.name_self_exception', state: state_descriptor_name)
            end
          end
        end
      end

      def check_for_duplicate_transition_names
        resource_descriptor.states.each do |secondary_descriptor_name, secondary_descriptor|
          secondary_descriptor.each do |state_descriptor_name, state_descriptor|
            transitions = state_descriptor.transitions.values.map { |v| v.name }
            if (dups = transitions.select { |t| transitions.count(t) > 1 }.uniq)
              dups.reject{ |name| name == 'self' }.each do |transition|
                add_error('states.name_duplicated_exception', state: state_descriptor_name, transition: transition)
              end
            end
          end
        end
      end

      # test to see if the state section has content
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
            if state.transitions.empty?
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

      # checks for a variety of potential errors with a state transition
      def check_resource_state_transitions(resource_name, curr_state, states_list)
        curr_state.transitions.values.each do |transition|
          transition_decorator = StateTransitionDecorator.new(transition)
          options = {resource: resource_name, state: curr_state.name, transition: transition.id}
          #9
          add_error('states.next_property_missing', options) unless transition.next
          #10 Transition next property has no value
          add_error('states.empty_missing_next', options) if transition.next && transition.next.empty?
          #13 Transition conditions property has no value(s)
          add_error('states.no_conditions_values', options) if transition_decorator.missing_condition_item?
          #11
          phantom_state_transition_check(states_list, resource_name, curr_state.name, transition_decorator) if
            transition.next
          #14
          add_warning('states.no_self_property', options) if transition_decorator.is_specified_name_property_not_self?
        end
      end

      #11, check to see if any next transition maps to an existing state. Check for null values at every level.
      # No need to check if the next transition points to an external resource (e.g. 'location')
      def phantom_state_transition_check(states_list, resource_name, curr_state_name, transition_decorator)
        transition_decorator.next.each do |next_state|
          if transition_decorator.is_next_state_a_location?
            validate_external_profile(resource_name, curr_state_name, transition_decorator)
          else
            unless states_list.include?(next_state)
              add_error('states.phantom_next_property', secondary_descriptor: resource_name, state: curr_state_name,
                transition: transition_decorator.name, next_state: next_state)
            end
          end
        end
      end

      # check to see if an external link to another profile is setup correctly and is downloaded to local cache
      def validate_external_profile(resource_name, state_name, transition_decorator)
        external_document_store  = Crichton::ExternalDocumentStore.new
        return if external_document_store.get(transition_decorator.next_state_location)
        response, body = external_document_store.send(:download, transition_decorator.next_state_location)
        if response == 200
          add_warning('states.download_external_profile', link: transition_decorator.next_state_location,
            secondary_descriptor: resource_name, state: state_name, transition: transition_decorator.name)
        else
          add_error('states.invalid_external_location', link: transition_decorator.next_state_location,
            secondary_descriptor: resource_name, state: state_name, transition: transition_decorator.name)
        end
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

    # class to override Crichton::Descriptor::StateTransition to perform deep level data access and checks on states
    # attributes
    class StateTransitionDecorator < Crichton::Descriptor::StateTransition
      ##
      # Constructor
      #
      # @param [Crichton::Descriptor::StateTransition] transition the current state transition
      def initialize(transition)
        super(transition.resource_descriptor, transition.descriptor_document, transition.id)
      end

      # distinguish non-existent condition statement from empty condition set
      def missing_condition_item?
        descriptor_document['conditions'] && conditions.empty?
      end

      # checks to see if the next state is a location
      def is_next_state_a_location?
        self.next.any? { |next_state| next_state.is_a?(Hash) && next_state['location'] }
      end

      # does basic checks for next transitions
      def is_specified_name_property_not_self?
        id != name && name != 'self' && !is_next_state_a_location?
      end

      # @return [Hash] the next state's location, if any
      def next_state_location
        self.next.first['location']
      end
    end
  end
end
