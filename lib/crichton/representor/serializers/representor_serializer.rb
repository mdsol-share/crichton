require 'representors/representor_builder'
require 'representors/representor'

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

      def to_representor(options)
        representor_hash = {
          attributes: get_semantic_data(options),
          transitions: get_transition_data(options),
          embedded: get_embedded_data(options)
        }
        Representors::Representor.new(representor_hash)
      end

      def as_media_type(options)
        to_representor(options).as_media_type(options)
      end

      def get_semantic_data(options)
        object.each_data_semantic(options).map { |semantic| to_attribute(semantic) }
      end

      def get_transition_data(options)
        object.each_transition(options).map { |transition| to_transition(transition) }
      end

      def get_embedded_data(options)
        object.each_embedded_semantic(options).map do |semantic|
          embedded_representor = semantic.value.map { |embedded| embedded.to_representor(options) }
          { semantic.name => embedded_representor }
        end
      end

      private
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
        rel = element.name ? { rel: element.name } : {}
        doc = element.doc ? { doc: element.doc } : {}
        rt = element.rt ? { rt: element.rt } : {}
        method = element.interface_method ? { method: element.interface_method } : {}
        href = element.templated? ? { href: element.templated_url } : { href: element.url }
        transition = rel.merge(doc).merge(href).merge(rt).merge(method)
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
