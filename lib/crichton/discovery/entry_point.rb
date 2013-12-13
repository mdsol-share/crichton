require 'crichton/representor/serializer'
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
      # Serlialization method for json_home and html
      #
      # @param media_type [Symbol] :json_home or :html
      # @param resource_relation [Hash] Hash of options for serialization
      def as_media_type(media_type, options = {})
        case media_type
          when :html
            # maybe generate a link
            # access option builder in xhtml.rb manual!
          else
            super
        end
      end

      ##
      # Returns a string representing a serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def to_media_type(media_type, options)
        as_media_type(media_type, options).to_s
      end

      ##
      #
      # Returns the url of the entry point of a resource
      #
      # @return [String] fully qualified url of the resource's entry point
      def url
        "#{Crichton.config.deployment_base_uri}/#{resource_uri}"
      end

      ##
      #
      # Returns a fully qualified alps based relation name of the resource
      #
      # @return [String] fully qualified url of the resource's relation name
      def rel
        "#{Crichton.config.alps_base_uri}/#{resource_id}/##{transition_id}"
      end

      ##
      #
      # Equality operator for adding EntryPoints into a set collection
      def ==(other_klass)
        self.resource_relation == other_klass.resource_relation
      end
    end
  end
end
