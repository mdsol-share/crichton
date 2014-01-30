require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor

    ##
    # Manages the serialization of a Crichton::Representor to an application/vnd.hale+json media-type.
    class HaleJsonSerializer < Serializer
      media_types hale_json: %w(application/vnd.hale+json)
      
      #maps descriptor datatypes to simple datatypes
      SEMANTIC_TYPES = {
        select: "text", #No way in Crichton to distinguish [Int] and [String]
        search:"text",
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
        :"datetime-local" => "text"
      }
      ##
      # Returns a ruby object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        halelets = []
        halelets << get_semantic_data(options)
        halelets << get_data(@object.each_transition(options), relations)
        halelets << get_data(@object.metadata_links(options), relations)
        base_object = halelets.reduce(&:deep_merge)
        add_embedded(base_object, options)
      end

      ##
      # Returns a json object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def to_media_type(options)
        as_media_type(options).to_json
      end

      private

      def deep_merge(x, y)
        x.deep_merge(y)
      end

      def semantic_map(sem)
        {type: "#{SEMANTIC_TYPES[sem.to_sym]}:#{sem}"}
      end
      
      
      def hale_links(transition_name, transition_semantic, attrib_or_params, data)
        { _links: { transition_name => { attrib_or_params => { transition_semantic.name => data } } } }
      end
      
      def hale_meta_options(transition_semantic)
        options = transition_semantic.options
        opts = { _source: options.source, _target: options.target || "." }
        { _meta: { "#{transition_semantic.name}_options" =>  opts } }
      end
      
      def get_options(transition_semantic)
        options = transition_semantic.options
        hale_opts = { "#{transition_semantic.name}_options.options" => {} } if options.external?
        hale_opts = { :options => options.each { |k, v| {k => v} } } if options.enumerable?
        ->(name, ap) { hale_links(name, transition_semantic, ap, hale_opts || {} ) }
      end

      def get_control(transition_name, transition_semantic, attrib_or_params)
        type_data = semantic_map(transition_semantic.field_type)
        validators = type_data.merge(handle_validator(transition_semantic.validators))
        halelet = hale_links(transition_name, transition_semantic, attrib_or_params, validators)
        halelet_opt = get_options(transition_semantic).(transition_name, attrib_or_params)
        hale_meta = transition_semantic.options.external? ? hale_meta_options(transition_semantic) : {}
        halelet.deep_merge(halelet_opt).deep_merge(hale_meta)
      end

      def relations
        ->(transition) { get_form_transition(transition) }
      end

      def get_link_transition(transition)
        link = { href: transition.url }
        link = { href: transition.templated_url, templated: true } if transition.templated?
        method = defined?(transition.interface_method) ? transition.interface_method : 'GET'
        link = link.merge({ method: method }) unless method == 'GET'
        link[:href] ? { _links: { transition.name => link } } : {}
      end
      
      def handle_validator(validators)
        validators["required"] = true if validators.has_key?("required")
        validators
      end
      
      def get_form_transition(transition)
          form_elements = {}
          semantics = defined?(transition.semantics) ? transition.semantics : {}
          semantics.values.each do |semantic|
            if semantic.semantics.any?
              _elements = semantic.semantics.values.map { |form_semantic| get_control(transition.name, form_semantic, "attributes") }
              form_elements.merge!(_elements.reduce(&:deep_merge))
            else
              form_elements.merge!(get_control(transition.name, semantic, "parameters"))
            end
          end
          link = get_link_transition(transition)
          link.deep_merge(form_elements)
      end
      
      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = ->(descriptor) { { descriptor.name => descriptor.value } }
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map(&transformation).reduce(&:deep_merge) ]
      end

      def add_embedded(base_object, options)
        if (embedded = get_embedded(options)) && embedded.any?
          base_object[:_embedded] = embedded
          add_embedded_links(base_object, embedded)
        end
        base_object
      end

      def add_embedded_links(base_object, embedded)
        embedded_links = embedded.reduce({}) { |h, (k, v)| h[k] = get_base_links(v); h }
        base_object[:_links] = base_object[:_links].merge(embedded_links)
      end

      def get_embedded(options)
        @object.each_embedded_semantic(options).inject({}) do |hash, semantic|
          hash[semantic.name] = get_embedded_elements(semantic, options) ; hash
        end
      end

      def get_base_links(hale_obj)
        hale_obj.map { |item| { href: item[:_links]['self'][:href], type: item[:_links]['type'][:href] } }
      end

      #Todo: Move to a helpers.rb file
      def map_or_apply(unknown_object, function)
        unknown_object.is_a?(Array) ? unknown_object.map(&function) : function.(unknown_object)
      end

      #Todo: Make Representor::xhtml refactored similarly
      def get_embedded_elements(semantic, options)
        map_or_apply(semantic.value, ->(object) { get_embedded_hale(object, options) })
      end

      def get_embedded_hale(object, options)
        object.as_media_type(self.class.default_media_type, options)
      end
    end
  end
end
