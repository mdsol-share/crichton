module Crichton
  ##
  # Adds lazy-loaded nested descriptors to descriptor classes.
  #
  # Requires the presence of a <tt>descriptor_document</tt> property on classes including this module that 
  # returns a hash of descriptors keyed by the descriptor id.
  module NestedDescriptors
    ##
    # The nested semantic descriptors.
    #
    # @return [Hash] The semantic descriptor instances.
    def semantics
      @semantics ||= build_descriptors(:semantics)
    end

    ##
    # The nested transition descriptors.
    #
    # @return [Hash] The transition descriptor instances.
    def transitions
      @transitions ||= build_descriptors(:transitions)
    end
    
  private
    def build_descriptors(nesting)
      klass = nesting == :semantics ? SemanticDescriptor : TransitionDescriptor
      (descriptor_document[nesting.to_s] || {}).inject({}) do |h, (id, descriptor_hash)|
        h[id] = klass.new(descriptor_hash, {id: id}); h
      end
    end
  end
end
