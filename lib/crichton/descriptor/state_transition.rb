require 'crichton/descriptor/base'

module Crichton
  module Descriptor
    # Manages transitions defined for states. 
    #
    class StateTransition < Base
      ## 
      # @!attribute [r] conditions
      # The condition options that indicate a transition should be included in a response that represents the
      # associated state of a resource.
      #
      # @return [Array] The conditions.
     descriptor_reader :conditions

      ## 
      # @!attribute [r] next
      # The next states that are possible if the transition is executed. 
      #
      # This will either be a single state or possibly the error state and a success state. Used to generate
      # state machine diagrams associated with resources.
      #
      # @return [Array] The next state(s).
     descriptor_reader :next
    end
  end
end
