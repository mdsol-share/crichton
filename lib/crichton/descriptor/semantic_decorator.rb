require 'crichton/descriptor/detail'

module Crichton
  module Descriptor
    class SemanticDecorator < Detail
      
      def initialize(target, descriptor)
        super(descriptor.resource_descriptor, descriptor.descriptor_document)
        @target = target
      end
      
      def value
        # TODO: Decide if send should be #try to make this more friendly if the value is not there
        @target.is_a?(Hash) ? @target[source] : @target.send(source)
      end
      
      def present?
        @target.is_a?(Hash) ? @target.key?(source) : @target.respond_to?(source)
      end
    end
  end
end
