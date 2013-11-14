module Crichton
  module Descriptor
    ##
    # Manages options for select lists
    class Options
      # @private
      HREF = 'href'
      # @private
      EXTERNAL_HASH = 'external_hash'
      # @private
      EXTERNAL_LIST = 'external_list'
      # @private
      HASH = 'hash'
      # @private
      LIST = 'list'

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



      def internal_select?
        (opts = options) && (opts.include?(HASH) || opts.include?(LIST))
      end

      def datalist?
        (opts = options) && opts.include?('datalist')
      end

      def datalist_name
        options['datalist']
      end


      def external_hash
        (opts = options) && opts[EXTERNAL_HASH]
      end


      def external_list
        (opts = options) && opts[EXTERNAL_LIST]
      end

      def external_select?
        (opts = options) && (opts.include?(EXTERNAL_HASH) || opts.include?(EXTERNAL_LIST))
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
      
      def text_key
        options['text_attribute_name']
      end

      def value_key
        options['value_attribute_name']
      end
    end
  end
end
