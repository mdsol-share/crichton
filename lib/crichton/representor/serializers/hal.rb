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
        base_object = get_semantic_data(options)
        base_object[:_links] = get_links(options)
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
        links = get_link_transitions(options)
        links = links.merge(get_metadata_links(options))
        links.merge(get_embedded_transitions(options))
      end

      def get_link_transitions(options)
        get_transitions(@object.each_link_transition(options), options)
      end

      def get_transitions(link_transitions, options)
        relations = lambda do |transition|
          (transition.templated? ?
              [transition.name, {href: transition.templated_url, templated: true}] :
              [transition.name, {href: transition.url}])
        end
        get_data(link_transitions, relations).reject {|k, v| not v[:href]}
      end

      def get_embedded_transitions(options)
        get_transitions(@object.each_embedded_transition(options), options)
      end

      def get_metadata_links(options)
        link_transitions = @object.metadata_links
        relations = lambda do |transition|
          [transition.name, {href: transition.url}]
        end
        get_data(link_transitions, relations)
      end

      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = lambda {|descriptor| [descriptor.name, descriptor.value]}
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map(&transformation)]
      end

      def add_embedded(base_object, options)
        embedded = get_embedded(options)
        if embedded != {}
          base_object[:_embedded] = embedded
          base_object[:_links] = base_object[:_links].merge(embedded.inject({}) do |hash, k|
            hash.merge({k[0] => get_self_links(k[1])})
          end)
        end
        base_object
      end

      def get_embedded(options)
        esem = @object.each_embedded_semantic(options)
        esem.inject({}) do |hash, semantic|
          embedded_obj = {semantic.name => get_embedded_elements(semantic, options)}
          hash.merge(embedded_obj)
          end
      end

      def get_self_links(hal_obj)
        hal_obj.map do |item|
          {href: item[:_links]['self'][:href],
           type: item[:_links]['type'][:href]}
        end
      end

      def get_embedded_elements(semantic, options)
         case embedded_object = semantic.value
          when Array
            foo = embedded_object.map { |object| get_embedded_hal(object, options) }
          when Crichton::Representor
            foo = get_embedded_hal(embedded_object, options)
          else
            logger.warn("Semantic element should be either representor or array! Was #{semantic}")
        end
      end

      def get_embedded_hal(object, options)
        object.as_media_type(self.class.default_media_type, options)
      end
    end
  end
end
