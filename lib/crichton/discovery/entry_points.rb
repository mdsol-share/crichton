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
      # @param [Set] resources A Set collection of EntryPoint objects
      def initialize(resources)
        @resources = resources
      end

      ##
      #
      # Serialization method for root based requests
      #
      # @param media_type [Symbol] :json_home, :xhtml or :html
      # @param options [Hash] Hash of options to output styled or non-styled microdata
      # @option options [:symbol] :semantics Either :microdata (un-styled) or :styled_microdata
      def as_media_type(media_type, options)
        options = options.merge({semantics: :microdata}) if media_type == :xhtml
        case media_type
        when :html, :xhtml
          # build html document
          JsonHomeHtmlSerializer.new.as_media_type(@resources, options)
        else
          super
        end
      end

      ##
      #
      # Serialization method for root based requests
      #
      # @param media_type [Symbol] :json_home, :xhtml or :html
      # @param options [Hash] Hash of options to output styled or non-styled microdata
      # @option options [:symbol] :semantics Either :microdata (un-styled) or :styled_microdata
      def to_media_type(media_type, options = {})
        case media_type
        when :html, :xhtml
          # build html document
          as_media_type(media_type, options)
        else
          super
        end
      end
    end
  end
end
