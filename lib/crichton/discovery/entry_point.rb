require 'addressable/uri'

module Crichton
  module Discovery

    class EntryPoint

      ##
      #
      # @param [String] resource_uri_path uri of the entry point of the resource
      # @param [String] resource_name name of the resource relation
      # @param [String] resource_id name of the resource
      def initialize(resource_uri_path, resource_name, resource_id)
        @resource_uri_path = resource_uri_path
        @resource_name = resource_name
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

      ##
      #
      # Returns the name of the resource type
      #
      # @return [String] name of the resource type
      def name
        @resource_name
      end

      ##
      #
      # Returns the link relation type for the entry point, as a URL
      # reference the alps document. Example; if the resource name is called
      # 'studies' and supplied resource_id is "Studies" then this method
      # uses Critchton.config.alps_base_uri to create the following URI:
      # http://example.org/alps/Study#studies
      #
      # @return [String] URI of the link relation
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
