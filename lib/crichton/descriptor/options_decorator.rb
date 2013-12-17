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
        @decorated_options ||= if super && external
          if source.include?('://')
            return super
          end
          if @target.respond_to?(source)
            result = @target.send(source, super)
            raise_if_invalid(result.is_a?(Hash), throw("#{source} method on target must return Hash object"))

            [EXTERNAL, LIST, HASH].each do |x|
              if opts = result[x]
                raise_if_invalid(conditions[x].call(opts), throw)
                return result
              end
            end
            throw.call
          else
            super
          end
        else
          super
        end
      end

      private
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
