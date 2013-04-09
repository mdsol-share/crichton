require 'crichton/descriptors/nested'

module Crichton
  ##
  # Manages state transition information associated with resource descriptors.
  class TransitionDescriptor < Descriptor
    ##
    # The return value of the descriptor.
    #
    # @return [String] The return value reference.
    def rt
      descriptor_document['rt']
    end

    ##
    # The type of the descriptor.
    #
    # @return [String] The type.
    def type
      descriptor_document['type']
    end
  end
end
