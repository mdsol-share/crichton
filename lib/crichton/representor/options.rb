module Crichton
  module Representor
    ##
    # Manages options for select lists
    class Options

      SRC = 'src'
      def initialize(descriptor_options, object)
        if descriptor_options && descriptor_options.include?(SRC)
          src_sym = descriptor_options[SRC].to_sym
          descriptor_options = object.send(src_sym, descriptor_options) if object && object.respond_to?(src_sym)
        end
        @descriptor_options = descriptor_options
      end

      HREF = 'href'
      def options
        res = @descriptor_options.tap do |o|
          o.merge!(Crichton::options_registry[o.delete(HREF)]) if o && o.include?(HREF)
        end
        # Loop in the model in order to provide or override the options list/hash
        res
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
