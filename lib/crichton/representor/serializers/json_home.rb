require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class JsonHomeSerializer < Serializer
      media_types json_home: %w(application/json+home)

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
      def to_media_type(options  = {})
        as_media_type(options).to_json
      end

      private
      def generate_entry_points_hash
        @object.resources.inject({}) do |ep_hash, ep|
          ep_hash[ep.rel] = gen_href_hash(ep.url)
          ep_hash
        end
      end

      def gen_href_hash(resource_url)
        {:href => resource_url}
      end
    end
  end
end
