require 'crichton/descriptor/options'

module Crichton
  module Descriptor
    ##
    # Decorates options for select lists to access source values from a target.
    class OptionsDecorator < Options
      # @private
      SOURCE = 'source'
      
      def initialize(descriptor, target)
        super(descriptor.descriptor_document)
        @target = target
      end
      
      def options
        @decorated_options ||= if super && (source = super[SOURCE])
          # Loop in the model in order to provide or override the options list/hash
          @target.respond_to?(source) ? @target.send(source, super) : super
        else
          super
        end
      end
    end
  end
end
