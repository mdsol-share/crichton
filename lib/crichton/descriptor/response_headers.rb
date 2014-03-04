module Crichton
  module Descriptor
    class ResponseHeaders
      EXTERNAL = 'external'
      SOURCE = 'source'

      def initialize(descriptor, target)
        @descriptor = descriptor
        @target = target
      end

      def to_hash
        @header ||= if (external = descriptor[EXTERNAL])
          source = external[SOURCE]
          @target.respond_to?(source) ? respond_to_method(source) : {}
        else
          descriptor
        end
      end

      private
      def respond_to_method(method)
        result = @target.send(method)
        raise_if_invalid(result.is_a?(Hash), throw("#{method} method on target must return Hash object"))
        return result
      end

      def raise_if_invalid(condition, throw_function)
        throw_function.call unless condition
      end

      def throw(message = '')
        ->(){ raise Crichton::TargetMethodResponseError, message }
      end

      def descriptor
        @descriptor || {}
      end
    end
  end
end
