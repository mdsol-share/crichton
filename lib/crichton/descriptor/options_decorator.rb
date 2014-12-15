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
        @decorated_options ||= if super && (external = super[EXTERNAL])
          source = external[SOURCE]
          @target.respond_to?(source) ? respond_to_method(source, super) : super
        else
          super
        end
      end

      private
      def respond_to_method(method, options)
        result = @target.send(method, options)
        raise_if_invalid(result.is_a?(Hash), "#{method} method on target must return Hash object")

        [EXTERNAL, LIST, HASH].each do |x|
          if opts = result[x]
            raise_if_invalid(conditions[x].call(opts))
            return result
          end
        end
        throw_response_error("#{result} is invalid response type.")
      end

      def conditions
        {
          EXTERNAL => ->(opts) { (opts[SOURCE] && opts[TARGET] && opts[PROMPT]) },
          HASH => ->(opts) { opts.is_a?(Hash) },
          LIST => ->(opts) { opts.is_a?(Array) }
        }
      end

      def raise_if_invalid(condition, message = '')
        throw_response_error(message) unless condition
      end

      def throw_response_error(message)
        raise Crichton::TargetMethodResponseError, message
      end
    end
  end
end
