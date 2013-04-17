module Crichton
  module Descriptor  
    # Manages states defined for described resources.
    class State < Base
      ##
      # @!attribute [r] location
      # The location of the state in a state-machine. 
      #
      # Used to indicate the entry and exit nodes in a state-machine graph.
      #
      # @return [String] The state location, if any.
      descriptor_reader :location
  
      ##
      # Returns the transitions associated with the state.
      #
      # @return [Hash] The state transition descriptors.
      def transitions
        @transitions ||= (descriptor_document['transitions'] || []).inject({}) do |h, transition_descriptor|
          transition = StateTransition.new(resource_descriptor, transition_descriptor)
          h.tap { |hash| hash[transition.name] = transition }
        end.freeze
      end
    end
  end
end
