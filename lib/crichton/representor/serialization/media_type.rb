require 'crichton/representor/serializers/xhtml'
require 'crichton/representor/serializers/hale_json'
require 'crichton/representor/serializers/hal_json'
require 'crichton/representor/serializers/representor_serializer'


module Crichton
  module Representor
    module Serialization
      ##
      # Manages in-line serialization of  instances.
      module MediaType
        ##
        # Returns a serialized media-type for the response, as a Hash or XML.
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        #
        # @see #to_media_type for a list of possible options and example usage.
        def as_media_type(media_type, options = {})
          built_serializer(media_type, self, options).as_media_type(options)
        end

        def as_link(media_type, options = {})
          built_serializer(media_type, self, options).as_link(self_transition, options)
        end

        ##
        # Returns the final, serialized media-type for the response. This method differs from #as_media_type, which
        # returns a serialized object. It may be a hash or XML, for example. Serializers implement this method to 
        # convert the representation into the base media-type. For example, for a HAL JSON serializer, #as_media_type
        # would return a hash, but #to_media_type would return a JSON string.
        #
        # For documentation of options, see {file:doc/getting_started.md Getting Started}
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        # @option options [String, Symbol, Array] :conditions The state conditions.
        # @option options [String, Symbol, Array] :except The semantic data descriptor names to filter out.
        # @option options [String, Symbol, Array] :only The semantic data descriptor names to limit.
        # @option options [String, Symbol, Array] :include The embedded semantic descriptor names to include.
        # @option options [String, Symbol, Array] :exclude The embedded semantic descriptor names to exclude.
        # @option options [String, Symbol, Array] :additional_links Allows dynamically adding new links.
        # @option options [String, Symbol, Array] :override_links Allow overriding the URL set in links.
        # @option options [String, Symbol, Array] :state The state of the resource.
        def to_media_type(media_type, options = {})
          serializer = Crichton::Representor::RepresentorSerializer.new(self, options)
          representor = serializer.to_representor(options)
          representor.to_media_type(media_type, options)
          # serializer = built_serializer(media_type, self, options)
          # serializer.to_media_type(options).tap do
          #   yield serializer if block_given?
          # end
        end

        def respond_to?(method, include_private = false)
          (method =~ /^to_(\w*)$/) ? Crichton::Representor::Serializer.serializers?($1.to_sym) : super
        end

        def method_missing(method, *args, &block)
          (method =~ /^to_(\w*)$/) ? to_media_type($1.to_sym, *args, &block) : super
        end

        private
        def built_serializer(media_type, object, options)
          raise ArgumentError, 'The media_type argument cannot be blank.' if media_type.blank?

          # TODO: !slice serializer options related options
          Crichton::Representor::Serializer.build(media_type.to_sym, object, options)
        end
      end
    end
  end
end
