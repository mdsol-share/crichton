require 'crichton/descriptor/base'
require 'crichton/descriptor/state_transition'

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
        @transitions ||= (descriptor_document['transitions'] || {}).inject({}) do |h, (id, transition_descriptor)|
          h.tap { |hash| hash[id] = StateTransition.new(resource_descriptor, transition_descriptor, id) }
        end.freeze
      end

      #SHOULD BE IN A LOWER LEVEL OBJECT?
      def doc_property
         descriptor_document['doc']
      end

      def location
        descriptor_document['location']
      end
    end
  end
end
