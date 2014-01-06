require 'crichton/representor/serializer'
require 'crichton/representor/serializers/json_home'
require "json"

module Crichton
  module Discovery

    class EntryPoints
      include Crichton::Representor
      represents :entry_points

      attr_reader :resources

      ##
      #
      # Saves a collection of EntryPoint objects eventually used in serialization
      #
      # @params [Set] resources A Set collection of EntryPoint objects
      def initialize(resources)
        @resources = resources
      end

      ##
      #
      # Serlialization method for json_home and html
      #
      # @param media_type [Symbol] :json_home or :html
      # @param resource_relation [Hash] Hash of options for serialization
      def as_media_type(media_type, options = {})
        options = options.merge({semantics: :microdata}) if media_type == :xhtml
        case media_type
        when :html, :xhtml
          # build html document
          JsonHomeHtmlSerializer.new.to_media_type(@resources, options)
        else
          super
        end
      end

      alias :to_media_type :as_media_type
    end
  end
end
