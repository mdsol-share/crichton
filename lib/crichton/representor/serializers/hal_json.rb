require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class HalJsonSerializer < Serializer
      media_types hal_json: %w(application/hal+json)

      RESERVED_HREF = :href
      RESERVED_LINKS = :_links

      ##
      # Returns a ruby object representing a HAL serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        base_object = get_links(options).merge(get_semantic_data(options))
        add_embedded(base_object, options)
      end

      ##
      # Returns a json object representing a HAL serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def to_media_type(options)
        as_media_type(options).to_json
      end

      private

      def get_links(options)
        metadata_links = @object.metadata_links(options)
        link_transitions = @object.each_transition(options)
        all_links = [metadata_links, link_transitions]
        { RESERVED_LINKS => all_links.reduce({}) { |hash, link_block| hash.merge(get_data(link_block, relations)) } }
      end

      def relations
        lambda do |transition|
          link = if transition.templated?
                   {RESERVED_HREF => transition.templated_url, templated: true}
                 else
                   {RESERVED_HREF => transition.url}
                 end
          link[RESERVED_HREF] ? [transition.name, link] : nil
        end
      end

      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = ->(descriptor) {[descriptor.name, descriptor.value] }
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map(&transformation).compact]
      end

      def add_embedded(base_object, options)
        if (embedded = get_embedded(options)) && embedded.any?
          base_object[:_embedded] = embedded
          add_embedded_links(base_object, embedded)
        end
        base_object
      end

      def add_embedded_links(base_object, embedded)
        embedded_links = embedded.inject({}) { |hash, (k,v)| hash.merge({k => get_self_links(v)}) }
        base_object[RESERVED_LINKS] = base_object[RESERVED_LINKS].merge( embedded_links )
      end

      def get_embedded(options)
        @object.each_embedded_semantic(options).inject({}) do |hash, semantic|
          hash.merge({ semantic.name => get_embedded_elements(semantic, options) })
        end
      end

      def get_self_links(hal_obj)
        hal_obj.map { |item| { RESERVED_HREF => item[RESERVED_LINKS]['self'][RESERVED_HREF], type: item[RESERVED_LINKS]['type'][RESERVED_HREF] } }
      end

      #Todo: Move to a helpers.rb file
      def map_or_apply(unknown_object, function)
        unknown_object.is_a?(Array) ? unknown_object.map(&function) : function.(unknown_object)
      end

      #Todo: Make Representor::xhtml refactored similarly
      def get_embedded_elements(semantic, options)
        map_or_apply(semantic.value, ->(object) { get_embedded_hal(object, options) })
      end

      def get_embedded_hal(object, options)
        object.as_media_type(self.class.default_media_type, options)
      end
    end
  end
end
