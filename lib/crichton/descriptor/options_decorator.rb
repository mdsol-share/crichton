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
        @decorated_options ||= if super &&  (external = super[EXTERNAL])
          source = external[SOURCE]
          if source.include?('://')
            return super
          end
          if @target.respond_to?(source)
            unless (result = @target.send(source, super)).is_a?(Hash)
              raise Crichton::TargetMethodResponseError, "#{source} method on target must return Hash object"
            end

             if opts = result[EXTERNAL]
              raise Crichton::TargetMethodResponseError unless (opts[SOURCE] && opts[TARGET] && opts[PROMPT])
              result
            elsif opts = result[LIST]
              raise Crichton::TargetMethodResponseError unless opts.is_a?(Array)
              result
            elsif opts = result[HASH]
              raise Crichton::TargetMethodResponseError unless opts.is_a?(Hash)
              result
            elsif
              raise Crichton::TargetMethodResponseError
            end
          else
            super
          end
        else
          super
        end
      end
    end
  end
end
