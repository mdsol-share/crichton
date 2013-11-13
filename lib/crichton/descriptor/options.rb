module Crichton
  module Descriptor
    ##
    # Manages options for select lists
    class Options
      # @private
      HREF = 'href'
      
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
        (opts = options) && (opts.include?('hash') || opts.include?('list'))
      end

      def datalist?
        (opts = options) && opts.include?('datalist')
      end

      def datalist_name
        options['datalist']
      end

      def external_hash
        (opts = options) && opts['external_hash']
      end

      def external_list
        (opts = options) && opts['external_list']
      end

      def external_select?
        (opts = options) && (opts.include?('external_hash') || opts.include?('external_list'))
      end

      ##
      # Iterator allowing the generation of select lists from the values
      #
      # This iterator should provide a unified interface for generating option lists. It should avoid the need to
      # check if the option is a hash or list, so for both it uses two parameters for the yield.
      def each
        if opts =  options
          if opts.include? 'hash'
            opts['hash'].each { |k, v| yield k, v }
          elsif opts.include? 'list'
            opts['list'].each { |k| yield k, k }
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
