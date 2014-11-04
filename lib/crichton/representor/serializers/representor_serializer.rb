require 'representors'
require 'representors/representor_builder'
#require 'representors/representor'

module Crichton
  module Representor

    ##
    # Manages the serialization of a Crichton::Representor to a representor_hash instance.
    # TODO: THIS HAS TO BE REFACTORED TO USE RepresentorBuilder INTERFACE
    # TODO: WHEN RepresentorBuilder INTERFACE READY
    class RepresentorSerializer
      attr_reader :object, :options

      TAG = 'descriptors'

      def initialize(object, options)
        @object, @options = object, options
      end
#       id: nil,
#           +      doc: nil,
#           +      href: nil,
#           +      attributes: {},
#           +      links: [],
#           +      transitions: [],
#           +      embedded: {}

      def to_representor(options)
        #@object.inspect
        builder = Representors::RepresentorBuilder.new({
          #id: @object.uuid, #Not working for some reason
          href: @object.self_transition.url,
          links: get_links(@object, options)
          #doc: # No Current Way to do this in Crichton
        })
        builder = get_semantic_data(builder, options)
        builder = get_transition_data(builder, options)
        builder = get_embedded_data(builder, options)
        builder.to_representor_hash
      end

      def as_media_type(options)
        to_representor(options)#.to_media_type(options)
      end
      
      private
       
      def get_semantic_data(builder, options)
        object.each_data_semantic(options).reduce(builder) do |builder, semantic| 
          builder.add_attribute(semantic.name, semantic.value, to_attribute(semantic))
        end
      end
      
      def get_links(object, options)
        links = object.metadata_links(options).map do |e|
          link = e.templated? ? e.templated_url : e.url
          transition = link ? to_transition(e) : nil
        end.reject(&:blank?)
        ret = {}
        links.each { |hash| ret[hash[:rel]] = hash[:href] }
        ret
      end

      def get_transition_data(builder, options)
        object.each_transition(options).reduce(builder) do |builder, transition| 
          link = transition.templated? ? transition.templated_url : transition.url
          link ? builder.add_transition(transition.name, link, to_transition(transition)) : builder
        end
      end

      def map_or_apply(unknown_object, function)
        unknown_object.is_a?(Array) ? unknown_object.map(&function) : function.(unknown_object)
      end

      
      def get_embedded_data(builder, options)
        @object.each_embedded_semantic(options).inject(builder) do |builder, semantic|
          builder.add_embedded(semantic.name, get_embedded_elements(semantic, options))
        end
      end
      
      def get_embedded_elements(semantic, options)
        map_or_apply(semantic.value, ->(object) { get_embedded_hale(object, options) })
      end

      def get_embedded_hale(object, options)
        RepresentorSerializer.new(object, options).as_media_type(options)#.inspect
      end
      

      def to_attribute(element)
        semantics = element.semantics.map { |name, semantic| { name => to_attribute(semantic) } }
        doc = element.doc ? { doc: element.doc } : {}
        type = element.type ? { type: element.type } : {}
        sample = element.sample ? { sample: element.sample } : {}
        value = element.source_defined? ? { value: element.value } : {}
        profile = element.href ? { profile: element.href } : {}
        field_type = element.field_type ? { field_type: element.field_type } : {}
        validators = element.validators.any? ? { validators: element.validators } : {}
        #TODO: need to add options
        attribute = doc.merge(type).merge(sample).merge(value).merge(profile).merge(field_type).merge(validators)
        semantics.any? ? attribute.merge(TAG => semantics) : attribute
      end

      def to_transition(element)
        transition = {}
        [:rel, :name, :doc, :rt, :interface_method].map do |attribute|
          if (element.respond_to?(attribute) && element.send(attribute))
            transition[attribute] = element.public_send(attribute)
          end
        end
        transition[:method] = transition[:interface_method] if transition.include?(:interface_method)               
        transition[:href] = element.templated? ? element.templated_url : element.url
        descriptors = {}
        if element.templated?
          descriptors = element.semantics.values.each_with_object({}) do |semantic, h|
            h.merge!(semantic.name => to_attribute(semantic))
          end
        end
        descriptors.any? ? transition.merge(TAG => descriptors) : transition
      end

    end
  end
end
