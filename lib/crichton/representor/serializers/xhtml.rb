require 'crichton/representor/serializer'

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/xhtml+xml media-type.
    class XHTMLSerializer < Serializer
      alternate_media_types :html
      
      ##
      # Returns a representation of the object as xhtml.
      #
      # @param [Hash] options Optional configurations.
      # @option options [Integer] :indent Sets indentation of the tags. Default is 2.
      # @option options [Symbol] :semantics Indicates the semantic markup type to apply. Valid options are
      #  :microdata and :styled_microdata. If not included, defaults to :microdata.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = nil)
        options ||= {}
        configure_markup_builder(options)

        if options[:top_level] != false       
          @markup_builder.declare!(:DOCTYPE, :html)
          @markup_builder.tag!(:html, xmlns: 'http://www.w3.org/1999/xhtml') do
            add_head
            add_body(options)
          end
        else
          add_embedded_element(options)
        end
      end
      
    private
      def configure_markup_builder(options)
        require 'builder' unless defined?(::Builder)

        options[:indent]  ||= 2
        options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
        @markup_builder = options[:builder]
        
        configure_semantic_builder(options)     
      end
      
      def configure_semantic_builder(options)
        semantics = options[:semantics].to_sym if options[:semantics]
        
        klass = case semantics
                when :styled_microdata
                  StyledMicrodataSemanticBuilder
                else
                  MicrodataSemanticBuilder
                end
        
        @semantic_builder = klass.new(self.class.media_type, @object, @markup_builder)
      end
      
      def add_head
        @semantic_builder.add_head
      end
      
      def add_body(options)
        @semantic_builder.add_body(options)
      end
      
      def add_embedded_element(options)
        @semantic_builder.add_embedded_element(options)
      end
      
      ## 
      # Manages Abstract Base functionality for semantic Builders that implement the specifics of Hypermedia 
      # serialization per ALPS media-type guidance specs for HTML.
      class BaseSemanticBuilder

        # @param [Symbol] media_type The media type the builder builds. Used for nested semantic objects.
        # @param [Crichton::Representor] object The object to build semantics for.
        # @param [Builder::XmlMarkup] markup_builder The primary builder.
        def initialize(media_type, object, markup_builder)
          @media_type, @object, @markup_builder = media_type, object, markup_builder
        end

        # @!macro add_head
        #   Adds the head tag and any relevant child tags.
        def add_head
          @markup_builder.head do
            add_metadata_links
          end
        end

        # @!macro add_body
        #   Adds the body tag and all child tags.
        def add_body(options)
          @markup_builder.body do
            add_embedded_element(options)
          end
        end

        # @!macro add_embedded_element
        #   Adds a nested element and its associated tags to its parent tag.
        def add_embedded_element(options)
          @markup_builder.tag!(element_tag, element_attributes) do
            add_transitions(options)
            add_semantics(options)
          end
        end

        # @!macro element_tag
        #   Returns the parent tag of a built element.
        def element_tag
          raise_abstract('element_tag')
        end

      private
        def element_attributes
          {itemscope: 'itemscope'}.tap do |attributes|
            if type_link = @object.class.instance_eval { resource_descriptor.type_link }
              attributes[:itemtype] = type_link.href
            end
          end
        end

        def add_metadata_links
          @object.metadata_links.each { |metadata_link| @markup_builder.tag!(:link, metadata_link.attributes) }
        end

        def add_transitions(options)
          @object.each_link_transition(options) do |transition|
            transition.templated? ? add_templated_transition(transition, options) : add_transition(transition)
          end

          @object.each_embedded_transition(options) { |transition| add_transition(transition) }
        end

        def add_templated_transition(transition, options)
          if transition.safe?
            add_query_transition(transition)
          else
            add_control_transition(transition)
          end
        end

        def add_query_transition(transition)
          @markup_builder.a(transition.name, {rel: transition.name, href: transition.templated_url}) if transition.url
        end

        def add_control_transition(transition)
          raise_abstract('add_control_transition')
        end

        def add_transition(transition)
          Crichton::logger.warn("Transition URL is nil for #{transition}!")
          @markup_builder.a(transition.name, {rel: transition.name, href: transition.url}) if transition.url
        end

        def add_semantics(options)
          @object.each_data_semantic(options) do |semantic|
            add_semantic(semantic, options)
          end

          options[:top_level] = false
          @object.each_embedded_semantic(options) do |semantic|
            add_embedded_semantic(semantic, options)
          end
        end
        
        def add_semantic(semantic, options)
          raise_abstract('add_semantic')
        end
        
        def add_embedded_semantic(semantic, options)
          embedded_element_attributes = {itemscope: 'itemscope', itemtype: semantic.href, itemprop: semantic.name}

          @markup_builder.tag!(element_tag, embedded_element_attributes) do
            case embedded_object = semantic.value
            when Array
              embedded_object.each { |object| add_embedded_object(object, options) }
            when Crichton::Representor
              add_embedded_object(embedded_object, options)
            else
              Crichton::logger.warn("Semantic element should be either representor or array! Was #{semantic}")
            end
          end
        end
        
        def add_embedded_object(object, options)
          object.as_media_type(@media_type, options)
        end
        
        def raise_abstract(method)
          raise "##{method} is an abstract method that must be implemented."
        end
      end
      
      ##
      # Manages building HTML elements with Microdata semantics.
      class MicrodataSemanticBuilder < BaseSemanticBuilder
        
        # @!macro element_tag
        def element_tag
          :div
        end
        
      private
        def add_semantic(semantic, options)
          @markup_builder.span(semantic.value, itemprop: semantic.name)
        end

        def add_control_transition(transition, input_type = :text)
          method = transition.safe? ? transition.method : :post
          @markup_builder.form({action: transition.url, method: method, name: transition.name}) do
            transition.semantics.values.each do |semantic|
              # If this is a form semantic, pick up its attributes
              if semantic.semantics.any?
                semantic.semantics.values.each { |form_semantic| add_control_input(form_semantic, input_type) }
              else
                add_control_input(semantic, input_type)
              end
            end
            @markup_builder.input({type: :hidden, name: '_method', value: transition.method}) unless transition.safe?
            @markup_builder.input({type: :submit, value: transition.name})
          end
        end
        
        def add_control_input(semantic, input_type)
          @markup_builder.input({itemprop: semantic.name, type: input_type, name: semantic.name})
        end
      end

      ##
      # Manages building HTML elements with Microdata semantics and includes styles and scripts for interacting with
      # the resource in a browser for 'surfing the API'.
      class StyledMicrodataSemanticBuilder < MicrodataSemanticBuilder
        # @!macro add_head
        def add_head
          @markup_builder.head do
            add_metadata_links
            add_style
          end
        end

        # @!macro element_tag
        def element_tag
          :ul
        end

      private
        def add_style
          @markup_builder.style do |style|
            style << "*[itemprop]::before {\n  content: attr(itemprop) \": \";\n  text-transform: capitalize;\n}\n"
          end
        end

        def add_transition(transition)
          return unless transition.url
          
          @markup_builder.li do
            super
          end
        end
        
        def add_semantic(semantic, options)
          @markup_builder.li do
            super
          end
        end

        def add_embedded_semantic(semantic, options)
          @markup_builder.li do
            super
          end
        end

        def add_embedded_object(object, options)
          @markup_builder.li do
            object.as_media_type(@media_type, options)
          end
        end

        def add_query_transition(transition)
          add_control_transition(transition, :search)
        end
        
        # Builds a form control
        def add_control_transition(transition, input_type = :text)
          method = transition.safe? ? transition.method : :post
          @markup_builder.li do
            @markup_builder.form({action: transition.url, method: method}) do
              @markup_builder.ul do
                transition.semantics.values.each do |semantic|
                  if semantic.semantics.any?
                    semantic.semantics.values.each { |form_semantic| add_control_input(form_semantic, input_type) }
                  else
                    add_control_input(semantic, input_type)
                  end
                end
              end
              @markup_builder.input({type: :hidden, name: '_method', value: transition.method }) unless transition.safe?
              @markup_builder.input({type: :submit, value: transition.name})
            end
          end
        end

        def add_control_input(semantic, input_type)
          @markup_builder.li do
            @markup_builder.label({itemprop: semantic.name}) do
              @markup_builder.input({type: input_type, name: semantic.name})
            end
          end
        end
      end
    end
  end
end
