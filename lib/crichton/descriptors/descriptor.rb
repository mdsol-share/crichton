require 'crichton/descriptors/nested'

module Crichton
  class Descriptor < BaseSemanticDescriptor
    include NestedDescriptors

    ##
    # Constructs a new instance of Descriptor.
    #
    # Subclasses MUST call <tt>super</tt> in their constructors and override the <tt>type</tt> method.
    #
    # @param [Hash] resource_descriptor The parent resource descriptor instance.                                                              # 
    # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
    # @param [Hash] options Optional arguments.
    # @option options [Symbol] :id Set or override the id of the descriptor.
    def initialize(resource_descriptor, descriptor_document, options = {})
      super(descriptor_document, options)
      @resource_descriptor = resource_descriptor
    end

    ##
    # The parent resource descriptor.
    #
    # @return [Hash] The resource descriptor.
    attr_reader :resource_descriptor
  end
end
