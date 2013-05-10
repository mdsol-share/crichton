require 'crichton/descriptor/detail'

module Crichton
  module Descriptor
    ##
    # Manages retrieving the data values associated with semantic descriptors from a target object.
    class SemanticDecorator < Detail
      
      ##
      # @param [Hash, Object] target The target instance to retrieve data from.
      # @param [Crichton::Descriptor::Detail] descriptor The Detail descriptor associated with the semantic data.
      def initialize(target, descriptor)
        super(descriptor.resource_descriptor, descriptor.parent_descriptor, descriptor.descriptor_document)
        @target = target
      end
      
      ##
      # The value of the data.
      #
      # @return [Object] The data value.
      def value
        # TODO: Add logging if a value is requested and the source in not defined vs. raising a MethodMissingError.
        @target.is_a?(Hash) ? @target[source] : @target.try(source)
      end
      
      ##
      # Whether the source of the data exists in the hash or object. This is not a <tt>nil?</tt> check, but rather 
      # determines if the related attribute is defined on the object.
      #
      # @return [Boolean] true, if the data source is defined.
      def source_defined?
        @target.is_a?(Hash) ? @target.key?(source) : @target.respond_to?(source)
      end
    end
  end
end
