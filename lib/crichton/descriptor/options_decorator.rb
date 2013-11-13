module Crichton
  module Descriptor
    ##
    # Manages options for select lists
    class OptionsDecorator

      HREF = 'href'
      SOURCE = 'source'
      def initialize(descriptor_options, object)
        if descriptor_options && descriptor_options.include?(HREF)
          descriptor_options = descriptor_options.merge(Crichton::options_registry[descriptor_options[HREF]])
          descriptor_options.delete(HREF)
        end
        # Loop in the model in order to provide or override the options list/hash
        if descriptor_options && descriptor_options.include?(SOURCE)
          src_sym = descriptor_options[SOURCE].to_sym
          descriptor_options = object.send(src_sym, descriptor_options) if object && object.respond_to?(src_sym)
        end
        @descriptor_options = descriptor_options
      end

      def options
        @descriptor_options
      end

      def is_internal_select?
        (opts = options) && (opts.include?('hash') || opts.include?('list'))
      end

      def is_datalist?
        (opts = options) && opts.include?('datalist')
      end

      def datalist_name
        options['datalist']
      end

      def is_external_select?
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
    end
  end
end
