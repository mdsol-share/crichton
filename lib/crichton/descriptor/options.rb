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
        @options ||= descriptor_document.dup.tap do |d|
          if href = d[HREF]
            d.merge!(Crichton::options_registry[href])
            d.delete(HREF)
          end
        end
      end

      def enumerable?
        (opts = options) && (opts.include?(HASH) || opts.include?(LIST))
      end

      def external?
        (opts = options) && opts.include?(EXTERNAL)
      end

      ##
      # Iterator allowing the generation of select lists from the values
      #
      # This iterator should provide a unified interface for generating option lists. It should avoid the need to
      # check if the option is a hash or list, so for both it uses two parameters for the yield.
      def each
        if opts =  options
          if opts.include?(HASH)
            opts[HASH].each { |k, v| yield k, v }
          elsif opts.include?(LIST)
            opts[LIST].each { |k| yield k, k }
          else
            Crichton::logger.warn("did not find list or hash key in options data: #{opts.to_s}")
          end
        end
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
