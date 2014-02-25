require 'crichton/descriptor/detail'
require 'crichton/descriptor/options_decorator'

module Crichton
  module Descriptor
    ##
    # Base class for decorating detail descriptors.
    class DetailDecorator < Detail

      # @param [Hash, Object] target The target instance to retrieve data from.
      # @param [Crichton::Descriptor::Detail] descriptor The Detail descriptor associated with the semantic data.
      def initialize(target, descriptor, options = {})
        super(descriptor.resource_descriptor, descriptor.parent_descriptor, descriptor.id,
          descriptor.descriptor_document)
        @target = target
        @_options = options || {}
      end
      
      ##
      # Decorated semantics.
      def semantics
        @semantics ||= begin
          require 'crichton/descriptor/semantic_decorator'
          super.inject({}) { |h, (k, v)| h[k] = SemanticDecorator.new(@target, v, @_options); h}
        end
      end

      ##
      # Decorated transitions.
      def transitions
        @transitions ||= begin
          require 'crichton/descriptor/transition_decorator'
          super.inject({}) { |h, (k, v)| h[k] = TransitionDecorator.new(@target, v, @_options); h }
        end
      end
    end
  end
end
