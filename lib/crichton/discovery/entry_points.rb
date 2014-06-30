require 'crichton/representor/serializers/hal_json'

module Crichton
  module Discovery

    class EntryPoints
      include Crichton::Representor
      ##
      #
      # Saves a collection of EntryPoint objects eventually used in serialization
      #
      # @param [Set] resources A Set collection of EntryPoint objects
      def initialize(entry_point_objects)
        @entry_point_objects = entry_point_objects
      end

      ##
      #
      # Serialization method for root based requests
      #
      # @param media_type [Symbol] :hale_json
      # @param options [Hash] Hash of options to output styled or non-styled microdata
      # @option options [:symbol] :semantics Either :microdata (un-styled) or :styled_microdata
      def as_media_type(media_type, options)
        case media_type
        when :hale_json
          HaleJsonEntryPointsSerializer.new(@entry_point_objects).to_json
        else
          super
        end
      end

      ##
      #
      # Serialization method for root based requests
      #
      # @param media_type [Symbol] :hale_
      # @param options [Hash] Hash of options to output styled or non-styled microdata
      # @option options [:symbol] :semantics Either :microdata (un-styled) or :styled_microdata
      def to_media_type(media_type, options = {})
        case media_type
        when :hale_json
          as_media_type(media_type, options)
        else
          super
        end
      end
    end

    class HaleJsonEntryPointsSerializer

      LINK_OBJECT_NAME = :name

      # Requires objects that have three methods: href, :link_relation, and :name.
      # href method should return the URL where resources can be found
      # name should return the type of the resource to be found at the URL
      # link_relation should return a URI in lieu of an IANA link relation type
      # (the URI should indicate more information about the type of resource)
      def initialize(entry_point_objects)
        @entry_point_objects = entry_point_objects
      end

      def to_json
        link_objects = @entry_point_objects.inject({}) do |link_objects, entry_point|
          link_objects[entry_point.link_relation] = Hash[Crichton::Representor::HalJsonSerializer::RESERVED_HREF,
                                                         entry_point.href,
                                                         LINK_OBJECT_NAME,
                                                         entry_point.name]
          link_objects
        end
        Hash[Crichton::Representor::HalJsonSerializer::RESERVED_LINKS, link_objects].to_json
      end
    end
  end
end
