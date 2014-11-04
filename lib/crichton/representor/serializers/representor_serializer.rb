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
        builder = Representors::RepresentorBuilder.new({
          id: @object.uuid,
          href: @object.self_transition.url,
          links: get_links(@object, options)
          #doc: # No Current Way to do this in Crichton
        })
        #print Representors::Representor.new(builder.to_representor_hash).to_yaml
        builder = get_semantic_data(builder, options)
        builder = get_transition_data(builder, options)
#           transitions: get_transition_data(options),
#           embedded: get_embedded_data(options)
#         }
        print Representors::Representor.new(builder.to_representor_hash).to_hash
        print Representors::Representor.new(builder.to_representor_hash).to_media_type(:hale_json)
        Representors::Representor.new(builder.to_representor_hash)
      end

      def as_media_type(options)
        to_representor(options).to_media_type(options)
      end
      
      def get_semantic_data(builder, options)
        #print object.each_data_semantic(options).map { |x| x.methods }
        object.each_data_semantic(options).reduce(builder) { |builder, semantic| builder.add_attribute(semantic.name, to_attribute(semantic)) }
      end
      
      def get_links(object, options)
        object.metadata_links(options).map do |e|
          link = e.templated? ? e.templated_url : e.url
          transition = link ? to_transition(e) : nil
#           print transition
#           print Representors::Transition.new(transition).to_hash
#           print Representors::Transition.new(transition).uri
#           print "\n"
          #transition[:r
        end.reject(&:blank?)


      def get_transition_data(builder, options)
        object.each_transition(options).reduce(builder) do |builder, transition| 
          link = transition.templated? ? transition.templated_url : transition.url
          link ? builder.add_transition(transition.name, link, to_transition(transition)) : builder
        end
      end

      def get_embedded_data(options)
        object.each_embedded_semantic(options).map do |semantic|
          embedded_representor = semantic.value.map { |embedded| embedded.to_representor(options).to_hash }
          { semantic.name => embedded_representor }
        end.inject({},&:merge)
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
        transition = {}
        [:rel, :name, :doc, :rt, :interface_method].map do |attribute|
          if (element.respond_to?(attribute) && element.send(attribute))
            transition[attribute] = element.public_send(attribute)
          end
        end
        transition[:method] = transition[:interface_method] if transition.include?(:interface_method)               
        transition[:href] = element.templated? ? element.templated_url : element.url
        print transition[:href]
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
