require 'crichton/representor/serializer'
require 'json'

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class JsonHomeSerializer < Serializer
      media_types json_home: %w(application/json+home)

      def initialize(object, options = nil)
        unless object.respond_to?(:resources)
          raise(Crichton::RepresentorError, "Target serializing object must be an EntryPoints object containing resources")
        end
        super(object, options)
      end
      ##
      # Returns a ruby object representing a JsonHome serialization.
      #
      # @return [Hash] The built representation.
      def as_media_type(options)
        { :resources => generate_entry_points_hash }
      end

      ##
      # Returns a json object representing a JsonHome serialization.
      #
      # @return [Hash] The built representation.
      def to_media_type(options = {})
        as_media_type(options).to_json
      end

      private
      def generate_entry_points_hash
        @object.resources.each_with_object({}) { |ep, ep_hash| ep_hash[ep.rel] = gen_href_hash(ep.url) }
      end

      def gen_href_hash(resource_url)
        {:href => resource_url}
      end
    end
  end
end
