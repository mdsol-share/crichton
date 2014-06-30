require 'addressable/uri'

module Crichton
  module Discovery

    class EntryPoint

      ##
      #
      # @param resource_uri [String] uri of the entry point of the resource
      # @param resource_relation [String] name of the resource relation
      # @param resource_id [String] name of the resource
      def initialize(resource_uri_path, resource_name, resource_id)
        @resource_name = resource_name
        @resource_uri_path = resource_uri_path
        @resource_id = resource_id
      end

      ##
      #
      # Returns the url of the entry point of a resource
      #
      # @return [String] fully qualified url of the resource's entry point
      def href
        Addressable::URI.parse(File.join(Crichton.config.deployment_base_uri, @resource_uri_path)).to_s
      end

      def name
        @resource_name
      end

      def link_relation
        Addressable::URI.parse(File.join(Crichton.config.alps_base_uri,"#{@resource_id}##{@resource_name}")).to_s
      end
      ##
      #
      # Equality operator for adding EntryPoints into a set collection
      def ==(other_klass)
        self.resource_name == other_klass.resource_name
      end
    end
  end
end
