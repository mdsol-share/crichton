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
          if source.include?('://')
            super
          elsif @target.respond_to?(source)
            respond_to_method(source, super)
          else
            super
          end
        else
          super
        end
      end

      private
      def respond_to_method(method, options)
        result = @target.send(method, options)
        raise_if_invalid(result.is_a?(Hash), throw("#{method} method on target must return Hash object"))

        [EXTERNAL, LIST, HASH].each do |x|
          if opts = result[x]
            raise_if_invalid(conditions[x].call(opts), throw)
            return result
          end
        end
        throw("#{result} is invalid response type.").call
      end

      def conditions
        {
          EXTERNAL => ->(opts) { (opts[SOURCE] && opts[TARGET] && opts[PROMPT]) },
          HASH => ->(opts) { opts.is_a?(Hash) },
          LIST => ->(opts) { opts.is_a?(Array) }
        }
      end

      def raise_if_invalid(condition, throw_function)
        throw_function.call unless condition
      end

      def throw(message = '')
        ->(message){ raise Crichton::TargetMethodResponseError, message }
      end
    end
  end
end
