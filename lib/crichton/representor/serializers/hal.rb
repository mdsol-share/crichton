require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class HalJsonSerializer < Serializer
      media_types hal_json: %w(application/hal+json)

      ##
      # Returns a ruby object representing a HAL serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        handle_non_representor
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

      #Todo: Determine proper Exception handling for non Crichton::Representor object
      def handle_non_representor
        unless @object.is_a? Crichton::Representor
          logger.warn("Semantic element should be either representor or array! Was #{@object.class.name}")
        end
      end

      def get_links(options)
        metadata_links = @object.metadata_links(options)
        link_transitions = @object.each_link_transition(options)
        embedded_transitions = @object.each_embedded_transition(options)
        all_links = [metadata_links, link_transitions, embedded_transitions]
        { _links: all_links.reduce({}) { |hash, link_block| hash.merge(get_data(link_block, relations)) } }
      end

      def relations
        ->(transition) do
          link = if transition.templated?
                   {href: transition.templated_url, templated: true}
                 else
                   {href: transition.url}
                 end
          link[:href] ? [transition.name, link] : nil
        end
      end

      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = lambda { |descriptor| [descriptor.name, descriptor.value] }
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map(&transformation)]
      end

      def add_embedded(base_object, options)
        embedded = get_embedded(options)
        embedded_links = embedded.reduce({}) { |hash, (k,v)| hash.merge({k => get_self_links(v)}) }
        base_object[:_links] = base_object[:_links].merge( embedded_links )
        base_object[:_embedded] = embedded unless embedded == {}
        base_object
      end

      def get_embedded(options)
        @object.each_embedded_semantic(options).inject({}) do |hash, semantic|
          hash.merge({ semantic.name => get_embedded_elements(semantic, options) })
        end
      end

      def get_self_links(hal_obj)
        hal_obj.map { |item| { href: item[:_links]['self'][:href], type: item[:_links]['type'][:href] } }
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
