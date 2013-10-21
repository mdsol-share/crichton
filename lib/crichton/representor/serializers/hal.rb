require 'crichton/representor/serializer'
require "json"
module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hal+json media-type.
    class HALSerializer < Serializer
      media_types hal: %w(application/json+hal)


      ##
      # Returns a representation of the object as xhtml.
      #
      # @param [Hash] options Optional configurations.
      # @option options [Integer] :indent Sets indentation of the tags. Default is 2.
      # @option options [Symbol] :semantics Indicates the semantic markup type to apply. Valid options are
      #  :microdata and :styled_microdata. If not included, defaults to :microdata.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        base_object = get_semantic_data
        base_object[:_links] = get_link_transitions(options)
        base_object[:_links] = base_object[:_links].merge(get_metadata_links)
        base_object[:_links] = base_object[:_links].merge(get_embedded_transitions)
        embedded = get_embedded(options)
        base_object[:_embedded] = {:items => embedded } if embedded
        if base_object[:_embedded]
          base_object[:_links][:list] = base_object[:_embedded][:items].map {|item| {href: item[:_links]["self"][:href], type:item[:_links]["type"][:href]}}#[:_links][:self]}
        end
        base_object
      end

      def to_media_type(options)
        base_object = as_media_type(options)
        json_obj = base_object.as_json
        json_obj = json_obj.to_json
        json_obj
      end

      private

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map &transformation]
      end

      def get_semantic_data
        semantic_data = @object.each_data_semantic
        each_pair = lambda {|descriptor| [descriptor.name, descriptor.value]}
        get_data(semantic_data, each_pair)
      end

      def get_link_transitions(options)
        link_transitions = @object.each_link_transition(options)
        relations = lambda {|transition|
          (transition.templated? ?
              [transition.name, {href: transition.templated_url, templated: true}] :
              [transition.name, {href: transition.url}])
        }
        get_data(link_transitions, relations)
      end

      def get_metadata_links
        link_transitions = @object.metadata_links
        relations = lambda {
            |transition| [transition.name, {href: transition.url}]}
        get_data(link_transitions, relations)
      end

      def get_embedded(options)
        @object.each_embedded_semantic.map { |semantic|
          get_embedded_elements(semantic, options)    }.first
      end

      def get_embedded_elements(semantic, options)
       #embedded_element_attributes = {itemscope: 'itemscope', itemtype: semantic.href, itemprop: semantic.name}
        case embedded_object = semantic.value
          when Array
            foo = embedded_object.map { |object| get_embedded_hal(object, options) }
          when Crichton::Representor
            foo = get_embedded_hal(embedded_object, options)
          else
            logger.warn("Semantic element should be either representor or array! Was #{semantic}")
        end
      end

      def get_embedded_transitions()
        link_transitions = @object.each_embedded_transition
        relations = lambda {|transition|
          (transition.templated? ?
              [transition.name, {href: transition.templated_url, templated: true}] :
              [transition.name, {href: transition.url}])
        }
        get_data(link_transitions, relations).reject {|k, v| not v[:href]}
      end

      def get_embedded_hal(object, options)
        object.as_media_type(self.class.default_media_type, options)
      end
    end
  end
end
