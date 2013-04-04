require 'crichton/descriptors/nested'

module Crichton
  ##
  # Manages semantic information associated with resource descriptors.
  class SemanticDescriptor < BaseDescriptor
    include NestedDescriptors
    
    ##
    # A sample value for the descriptor.
    #
    # @return [Object] The sample value.
    def sample
      descriptor_document['sample']
    end

    ##
    # The type of the descriptor.
    #
    # @return [String] The type.
    def type
      SEMANTIC
    end
  end
end
