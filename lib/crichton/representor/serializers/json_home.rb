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
      def as_media_type
        { :resources => generate_entry_points_array }
      end

      ##
      # Returns a json object representing a JsonHome serialization.
      #
      # @return [Hash] The built representation.
      def to_media_type
        as_media_type.to_json
      end

      private
      def generate_entry_points_array
        @object.resources.inject([]) do |arr, ep|
          arr << { gen_full_uri(ep.resource_uri) => gen_href_hash(ep.resource_relation) }
        end
      end

      def gen_full_uri(uri)
        "#{Crichton.config.deployment_base_uri}/#{uri}"
      end

      def gen_href_hash(resource_relation)
        {:href => resource_relation}
      end
    end
  end
end