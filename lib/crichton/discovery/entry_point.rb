require 'crichton/representor/serializer'
require 'addressable/uri'
require "json"

module Crichton
  module Discovery

    class EntryPoint
      include Crichton::Representor
      represents :entry_point

      attr_reader :resource_relation
      attr_reader :resource_uri
      attr_reader :transition_id
      attr_reader :resource_id

      ##
      #
      # @param resource_uri [String] uri of the entry point of the resource
      # @param resource_relation [String] name of the resource relation
      # @param transition_id [String] name of the transition that is the entry point for the resource
      # @param resource_id [String] name of the resource
      def initialize(resource_uri, resource_relation, transition_id, resource_id)
        @resource_relation =  resource_relation
        @resource_uri = resource_uri
        @transition_id = transition_id
        @resource_id = resource_id
      end

      ##
      #
      # Returns the url of the entry point of a resource
      #
      # @return [String] fully qualified url of the resource's entry point
      def url
        Addressable::URI.parse(File.join(Crichton.config.deployment_base_uri, resource_uri)).to_s
      end
      alias_method :href, :url

      alias_method :name, :resource_relation

      ##
      #
      # Returns a fully qualified alps based relation name of the resource
      #
      # @return [String] fully qualified url of the resource's relation name
      def rel
        Addressable::URI.parse(File.join(Crichton.config.alps_base_uri,"#{resource_id}#{trans_id}")).to_s
      end

      def link_relation
        Addressable::URI.parse(File.join(Crichton.config.alps_base_uri,"#{@resource_id}##{@resource_relation}")).to_s
      end
      ##
      #
      # Equality operator for adding EntryPoints into a set collection
      def ==(other_klass)
        self.resource_relation == other_klass.resource_relation
      end

      private
      def trans_id
        "##{transition_id}"
      end
    end
  end
end
