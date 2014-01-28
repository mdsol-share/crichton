require 'crichton/representor/serializer'
require "json"

class ::Hash
  def deep_merge(other)
    merger = ->(key, v1, v2) { 
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
    }
    self.merge(other, &merger)
  end
end

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/hale+json media-type.
    class HaleJsonSerializer < Serializer
      media_types hale_json: %w(application/hale+json)

      ##
      # Returns a ruby object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        halelets = []
        halelets += [get_semantic_data(options)]
        halelets += [get_data(@object.each_transition(options), relations)]
        halelets += [get_data(@object.metadata_links(options), links)]
        base_object = halelets.reduce { |x,y| x.deep_merge(y)}
        ret = add_embedded(base_object, options)
        ret
      end

      ##
      # Returns a json object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def to_media_type(options)
        haledoc = as_media_type(options)
        haledoc.to_json
      end

      private

      def semantic_map(sem)
        semantics = {
          select: ->(tn, x) {construct_form_semantic(tn, x, "text")}, #No way in Crichton to distinguis [Int] and [String]
          search: ->(tn, x) {construct_form_semantic(tn, x, "text")},
          text: ->(tn, x) {construct_form_semantic(tn, x, "text")},
          boolean: ->(tn, x) {construct_form_semantic(tn, x, "bool")}, #a Server should accept ?cat&dog or ?cat=cat&dog=dog
          number: ->(tn, x) {construct_form_semantic(tn, x, "number")},
          email: ->(tn, x) {construct_form_semantic(tn, x, "text")},     
          tel: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          datetime: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          time: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          date: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          month: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          week: ->(tn, x) {construct_form_semantic(tn, x, "text")}, 
          :"datetime-local" => ->(tn, x) {construct_form_semantic(tn, x, "text")}
        }

        semantics[sem]
      end
      
      def construct_form_semantic(transition_name, transition_semantic, type)
        halelet = {:_links => 
         {transition_name => 
          {:attributes =>
          {transition_semantic.name => 
           {type: type}.merge(handle_validator(transition_semantic.validators))
          }
         }}
        }
        halelet_opt = {}
        options = transition_semantic.options
        halelet_opt = if options.enumerable?
          {:_links => 
          {transition_name => 
            {:attributes =>
            {transition_semantic.name => 
              {:options => options.each { |k, v| {k => v} } }
              }
              }
              }
          } 
        elsif options.external?
          {:_meta =>
           {
            transition_semantic.name+"_options" => 
             {
              :_source => options.source,
              :_target => options.target
             }
           },
           :_links => 
            {
            transition_name => 
              {
               :attributes =>
                {
                 transition_semantic.name => 
                  {
                  transition_semantic.name+"_options.options" => {}
                  }
                }
              }
            }
          }
          
        else 
          {}
        end
        halelet.deep_merge(halelet_opt)
      end
      
      def links
        lambda do |transition|
          {:_links => {transition.name => {href: transition.url}}}
        end
      end
      
      def relations
        lambda do |transition|
          if transition.safe?
            get_link_transition(transition)
          else
            get_form_transition(transition)
          end

        end
      end

      def get_link_transition(transition)
          link = if transition.templated?
                   {href: transition.templated_url, templated: true}
                 else
                   {href: transition.url}
                 end
          link[:href] ? {:_links => {transition.name => link} } : {}
      end
      
      def handle_validator(validators)
        if validators.has_key?("required")
          validators["required"] = true
        end
        validators
      end
      
      def get_form_transition(transition)
          form_elements = false
          transition.semantics.values.each do |semantic|
            if semantic.semantics.any?
              form_elements = semantic.semantics.values.map { |form_semantic| get_control(transition.name, form_semantic) }
              form_elements = form_elements.reduce {|x,y| x.deep_merge(y) } 
            else
              form_elements = get_control(semantic.name, form_semantic)
            end
          end
          method = transition.method
          linkadd = if transition.templated?
                   {href: transition.templated_url, templated: true}
                 else
                   {href: transition.url}
                 end
          unless method == 'GET'
            linkadd = linkadd.merge({method: method})
          end
          link = {:_links => 
            {transition.name => linkadd}}
          if form_elements
            link = link.deep_merge(form_elements)
          end
          link
      end
 
      def get_control(transition_name, semantic)
         semantic_map(semantic.field_type.to_sym).(transition_name, semantic)
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
