require 'representors'
require 'representors/representor_builder'

module Crichton
  module Representor
    class RepresentorSerializer
      attr_reader :object, :options

      TAG = 'descriptors'

      SEMANTIC_TYPES = { # This perhaps should be in Representor
        select: "text", #No way in Crichton to distinguish [Int] and [String]
        search: "text",
        text: "text",
        boolean: "bool", #a Server should accept ?cat&dog or ?cat=cat&dog=dog
        number: "number",
        email: "text",
        tel: "text",
        datetime: "text",
        time: "text",
        date: "text",
        month: "text",
        week: "text",
        object: "object",
        :"datetime-local" => "text"
      }
      
      def initialize(object, options)
        @object, @options = object, options
      end

      def to_representor(options)
        buider_init = {}
        unless @object.self_transition.is_a?(Array) #FIXME: workaround for bug in representor.rb
          buider_init[:id] = @object.respond_to?(:uuid) ? @object.uuid : @object.self_transition.url
          buider_init[:href] =  @object.self_transition.url
        end
        buider_init[:links] = get_links(@object, options)

        builder = Representors::RepresentorBuilder.new(buider_init)
        builder = get_semantic_data(builder, options)
        builder = get_transition_data(builder, options)
        builder = get_embedded_data(builder, options)
        builder.to_representor_hash
      end

      def as_media_type(options)
        to_representor(options)
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
        end.reject{ |link| link.to_s == ''}
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

      def get_embedded_data(builder, options)
        @object.each_embedded_semantic(options).inject(builder) do |builder, semantic|
          builder.add_embedded(semantic.name, get_embedded_elements(semantic, options))
        end
      end

      def get_embedded_elements(semantic, options)
        map_or_apply(semantic.value) { |object| get_embedded_rep(object, options) }
      end

      def get_embedded_rep(object, options)
        RepresentorSerializer.new(object, options).as_media_type(options)
      end

      #TODO: If this stays in Crichton, we need integration specs testing that options actually get serialized
      def get_options(element)
        opts = element.options
        case
        when opts.nil?
          {}
        when opts.external?
          { 'external' => { source: opts.source, target: opts.target || "." } }
        when opts.enumerable?
          key = opts.type == Array ? 'list' : 'hash'
          { key => opts.values }
        end
      end

      # TODO: Refactor or move to Representors
      def to_attribute(element)
        semantics = element.semantics.map { |name, semantic| { name => to_attribute(semantic) } }
        doc = element.doc ? { doc: element.doc } : {}
        sample = element.sample ? { sample: element.sample } : {}
        value = element.source_defined? ? { value: element.value } : {}
        profile = element.href ? { profile: element.href } : {}
        field_type = element.field_type ? { field_type: element.field_type, type: SEMANTIC_TYPES[element.field_type.to_sym] } : {}
        validators = element.validators.any? ? { validators: element.validators } : {}
        validators[:validators] = validators[:validators].map { |h| h[-1].nil? ? h[0] : Hash[[h]] } if validators[:validators]
        scope = element.scope? ? { 'scope' => 'href' } : {}
        opts = element.options ? { options: get_options(element) } : {}
        attribute = doc.merge(sample).merge(value).merge(profile).merge(field_type).merge(validators).merge(scope).merge(opts)
        semantics.any? ? attribute.merge(TAG => semantics) : attribute
      end

      #TODO: Refactor or move to Representors
      def to_transition(element)
        transition = {}
        [:rel, :name, :doc, :rt, :interface_method].each do |attribute|
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

      def map_or_apply(unknown_object, &function)
        unknown_object.is_a?(Array) ? unknown_object.map(&function) : function.(unknown_object)
      end


    end
  end
end
