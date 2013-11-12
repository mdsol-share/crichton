require 'crichton/representor'

module Crichton
  module Representor
    module Factory
      class << self
        ##
        # Helper method to clear previously memoized factory classes.
        def clear_factory_classes
          @factory_classes = nil
        end
        
      private
        def factory_classes
          @factory_classes ||= {}
        end
      end

      ##
      # Wraps a target with an anonymous Crichton::Representor adapter.
      #
      # @param [Hash, Object] target The object to wrap.
      # @param [String, Symbol] resource The resource the adapter represents.
      #
      # @return [Object] The representor instance.
      def build_representor(target, resource)
        build(target, resource)
      end

      ##
      # Wraps a target with an anonymous Crichton::Representor adapter.
      #
      # @param [Hash, Object] target The object to wrap.
      # @param [String, Symbol] resource The resource the adapter represents.
      # @param [Hash] options Conditional options.
      # @option options [String, Symbol] :state The state of the target.
      # @option options [String, Symbol] :state_method The method or attribute on the target that returns the resource
      #   state.
      #
      # @return [Object] The representor instance.
      def build_state_representor(target, resource, options = nil)
        build(target, resource, state_options(options))
      end
      
    private
      def state_options(options)
        options ||= {}
        options = options.dup
        
        error_message = if options[:state] && options[:state_method]
          "Both :state and :state_method option set in '#{options.inspect}'. You must only set one of these options."
        elsif !(options[:state] || options[:state_method])
          "No :state or :state_method option set in '#{options.inspect}'. The method #build_state_representor " <<
            "requires one of these options. Use #build_representor if the resource does not implement states."
        end
        raise ArgumentError, error_message if error_message

        options[:use_state] = true
        options.slice(:use_state, :state, :state_method)
      end
     
      def build(target, resource, options = {})
        find_or_create_factory_class(resource, options).new(target, options[:state])
      end
      
      def find_or_create_factory_class(resource, options)
        # memoizes on resource and options which could be different for some reason for a particular resource.
        Factory.send(:factory_classes)[{resource => options}.to_s] ||= create_factory_class(resource, options)
      end

      def create_factory_class(resource, options)
        representor_module = options[:use_state] ? Crichton::Representor::State : Crichton::Representor
        options_state_method = options[:state_method]

        Class.new do
          include representor_module
          represents resource

          state_method options_state_method if options_state_method

          def initialize(target, state = nil)
            @target = target.is_a?(Hash) ? target.stringify_keys : target

            define_singleton_method(:state, lambda { state }) if state
          end

          ##
          # Use the *_options lambda from the collection if it is provided
          def method_missing(method, *args, &block)
            if @target.include?(method.to_s) && @target[method.to_s].is_a?(Proc)
              @target[method.to_s].call(*args)
            else
              super
            end
          end

          ##
          # Tell anyone who askes that we have the *_options lambda
          def respond_to?(method, include_private = false)
            (@target.include?(method.to_s) && @target[method.to_s].is_a?(Proc)) ? true : super
          end
        end
      end
    end
  end
end
