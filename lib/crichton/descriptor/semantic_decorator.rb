require 'crichton/descriptor/detail_decorator'
require 'crichton/descriptor/options_decorator'

module Crichton
  module Descriptor
    ##
    # Manages retrieving the data values associated with semantic descriptors from a target object.
    class SemanticDecorator < DetailDecorator
      
      ##
      # Whether the source of the data exists in the hash or object. This is not a <tt>nil?</tt> check, but rather 
      # determines if the related attribute is defined on the object.
      #
      # @return [Boolean] true, if the data source is defined.
      def source_defined?
        @target.is_a?(Hash) ? @target.key?(source) : @target.respond_to?(source)
      end
      alias :available? :source_defined?

      ##
      # The value of the data.
      #
      # @return [Object] The data value.
      def value
        val = @target.is_a?(Hash) ? @target[source] : @target.try(source)
        if val.nil?
          logger.warn("Source '#{source}' corresponding to descriptor #{name} is not defined on #{@target.inspect}. " <<
            "Make sure the object implements the source name or check for a misspelled descriptor key, name or source property.")
        end
        val
      end
      
      ##
      # The decorated options.
      def options
        @options ||= OptionsDecorator.new(super, @target)
      end
    end
  end
end
