require 'crichton/representor/serializer'
require "json"


module Crichton
  module Representor

    ##
    # Manages the serialization of a Crichton::Representor to an application/hale+json media-type.
    class HaleJsonSerializer < Serializer
      media_types hale_json: %w(application/vnd.hale+json)

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
        base_object = halelets.reduce { |x,y| x.deep_merge(y) }
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

      #maps drd datatypes to simple datatypes
      def semantic_map(sem)
        semantics = {
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

        {description: sem, type: semantics[sem.to_sym]}
      end
      
      def construct_hale_links(transition_name, transition_semantic, ap, data)
        {_links: 
         {transition_name => 
          {ap =>
            {transition_semantic.name => data
            }
          }
         }
        }
      end
      
      def construct_hale_meta_options(transition_semantic, options)
          {_meta:
           {"#{transition_semantic.name}_options" => 
             {
              _source: options.source,
              _target: options.target || "."
             }
           }
          }
      end     
      
      def get_options(transition_semantic, ap)
        options = transition_semantic.options
        hale_opts = if options.enumerable?
                      {:options => options.each { |k, v| {k => v} } }
                    elsif options.external?
                      { "#{transition_semantic.name}_options.options" => {} }
                    else
                      {}
                    end
        ->(name) { construct_hale_links(name, transition_semantic, ap, hale_opts) }
      end

      def get_control(transition_name, transition_semantic, ap)
        typedata = semantic_map(transition_semantic.field_type.to_sym)
        validators = typedata.merge(handle_validator(transition_semantic.validators))
        halelet = construct_hale_links(transition_name, transition_semantic, ap, validators)
        halelet_opt = get_options(transition_semantic, ap).(transition_name)
        hale_meta = if transition_semantic.options.external?
                      construct_hale_meta_options(transition_semantic, transition_semantic.options)
                    else
                      {}
                    end
        halelet.deep_merge(halelet_opt).deep_merge(hale_meta)
      end

      def relations
        lambda do |transition|
            get_form_transition(transition)
        end
      end

      def get_link_transition(transition)
        link = if transition.templated?
                  {href: transition.templated_url, templated: true}
               else
                  {href: transition.url}
               end
        method = 'GET'
        method = transition.interface_method if defined?(transition.interface_method)
        unless method == 'GET'
          link = link.merge({method: method})   
        end
        link[:href] ? {_links: {transition.name => link} } : {}
      end
      
      def handle_validator(validators)
        validators["required"] = true if validators.has_key?("required")
        validators
      end
      
      def get_form_transition(transition)
          form_elements = {}
          semantics = {}
          semantics = transition.semantics if defined?(transition.semantics)
          semantics.values.each do |semantic|
            if semantic.semantics.any?
              form_elements = semantic.semantics.values.map { |form_semantic| get_control(transition.name, form_semantic, "attributes") }
              form_elements = form_elements.reduce {|x,y| x.deep_merge(y) } 
            else
              form_elements = get_control(transition.name, semantic, "parameters")
            end
          end
          link = get_link_transition(transition)#{:_links => 
          link.deep_merge(form_elements)
      end
      
      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = ->(descriptor) {{descriptor.name => descriptor.value} }
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        dat = semantic_element.map(&transformation).reduce {|x,y| x.deep_merge(y) } 
        Hash[dat]
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
        base_object[:_links] = base_object[:_links].merge( embedded_links )
      end

      def get_embedded(options)
        @object.each_embedded_semantic(options).inject({}) do |hash, semantic|
          hash.merge({ semantic.name => get_embedded_elements(semantic, options) })
        end
      end

      def get_self_links(hale_obj)
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
