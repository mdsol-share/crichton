require 'crichton/descriptor/options'

module Crichton
  module Descriptor
    ##
    # Decorates options for select lists to access source values from a target.
    class OptionsDecorator < Options

      def initialize(descriptor, target)
        super(descriptor.descriptor_document)
        @target = target
      end

      def options
        @decorated_options ||= if @descriptor_document && (external = @descriptor_document[EXTERNAL])
          source = external[SOURCE]
          @target.respond_to?(source) ? @target.send(source, @descriptor_document) : @descriptor_document
        else
          @descriptor_document
        end
      end

    end
  end
end
