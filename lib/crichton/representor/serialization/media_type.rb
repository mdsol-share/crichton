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
        def as_media_type(media_type, options = {})
          built_serializer(media_type, self, options).as_media_type(options)
        end

        ##
        # Returns the final, serialized media-type for the response. This method differs from #as_media_type, which
        # returns a serialized object. It may be a hash or XML, for example. Serializers implement this method to 
        # convert the representation into the base media-type. For example, for a HAL JSON serializer, #as_media_type
        # would return a hash, but #to_media_type would return a JSON string.
        #
        # @param [Symbol, String] media_type The registered media-type associated with the desired serializer.
        # @param [Hash] options Conditional options to configure to the serialization.
        def to_media_type(media_type, options = {})
          built_serializer(media_type, self, options).to_media_type(options)
        end

        private
        def built_serializer(media_type, object, options)
          raise ArgumentError, 'The media_type argument cannot be blank.' if media_type.blank?

          # TODO: !slice serializer options related options
          Serializer.build(media_type.to_sym, object, options)
        end
      end
    end
  end
end