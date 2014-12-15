module Crichton
  module Descriptor
    ##
    # Manages options for select lists
    class Options
      # @private
      OPTIONS_VALUES = %w(id href hash list external source target prompt)
      HREF, HASH, LIST, EXTERNAL, SOURCE, TARGET, PROMPT = OPTIONS_VALUES[1..-1]

      attr_reader :descriptor_document

      def initialize(descriptor_document)
        @descriptor_document = descriptor_document
      end

      def options
        @options ||= descriptor_document.dup
      end

      def enumerable?
        (opts = options) && (opts.include?(HASH) || opts.include?(LIST))
      end

      def external?
        (opts = options) && opts.include?(EXTERNAL)
      end

      #@deprecated
      def each #TODO: Remove when XHTML Serialization is handled by Representor
        options.include?(HASH) ? options[HASH].each { |k, v| yield k, v } : options[LIST].each { |k| yield k, k }
      end

      def values
        options[HASH] || options[LIST]
      end

      def type
        options.include?(HASH) ? Hash : Array
      end

      def source
        external[SOURCE]
      end

      def prompt
        external[PROMPT]
      end

      def target
        external[TARGET]
      end

      private
      def external
        options[EXTERNAL]
      end

    end
  end
end
