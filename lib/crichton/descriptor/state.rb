require 'crichton/descriptor/base'
require 'crichton/descriptor/state_transition'
require 'crichton/descriptor/response_headers_decorator'

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

      def decorate(target)
        @response_headers ||= ResponseHeadersDecorator.new(descriptor_document['response_headers'] || {}, target)
      end

      ##
      # Returns the transitions associated with the state.
      #
      # @return [Hash] The state transition descriptors.
      def transitions
        @transitions ||= (descriptor_document['transitions'] || {}).inject({}) do |h, (id, transition_descriptor)|
          h.tap { |hash| hash[id] = StateTransition.new(resource_descriptor, transition_descriptor, id) }
        end.freeze
      end
    end
  end
end
