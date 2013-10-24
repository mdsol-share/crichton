require 'crichton/representor/serializer'
require 'crichton/helpers'

module Crichton
  module Representor
    ##
    # Manages the serialization of a Crichton::Representor to an application/xhtml+xml media-type.
    class XHTMLSerializer < Serializer
      media_types xhtml: %w(application/xhtml+xml), html: %w(text/html)

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

      def as_link(self_transition, options)
        configure_markup_builder(options)
        @markup_builder.tag!(:a, @object.uuid, href: self_transition.url)
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
        
        @semantic_builder = klass.new(self.class.default_media_type, @object, @markup_builder)
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
        include Crichton::Helpers::ConfigHelper

        ##
        # Helper to access the Crichton configuration locally
        #
        # @return [Configuration] Configuration object
        def config
          @config ||= Crichton.config
        end

        # @param [Symbol] media_type The media type the builder builds. Used for nested semantic objects.
        # @param [Crichton::Representor] object The object to build semantics for.
        # @param [Builder::XmlMarkup] markup_builder The primary builder.
        def initialize(media_type, object, markup_builder)
          @media_type, @object, @markup_builder = media_type, object, markup_builder
        end

        # @!macro add_head
        #   Adds the head tag and any relevant child tags.
        def add_head
          @markup_builder.head { add_metadata_links }
        end

        # @!macro add_body
        #   Adds the body tag and all child tags.
        def add_body(options)
          @markup_builder.body { add_embedded_element(options) }
        end

        # @!macro add_embedded_element
        #   Adds a nested element and its associated tags to its parent tag.
        def add_embedded_element(options)
          @markup_builder.tag!(element_tag, element_attributes) do
            add_transitions(options)
            add_semantics(options)
          end
        end

        # @!macro add_control
        #   Adds HTML tag of specific kind to its parent tag.
        def add_control(semantic)
          case semantic.field_type.to_sym
          when :select
            add_control_select(semantic)
          when :boolean
            add_control_boolean(semantic)
          else
            add_control_input(semantic)
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
            if transition.safe?
              add_link_transition(transition)
            else
              add_form_transition(transition)
            end
          end

          @object.each_embedded_transition(options) { |transition| add_link_transition(transition) }
        end

        def add_link_transition(transition)
          @markup_builder.a(transition.name, {rel: transition.name, href: transition.templated_url}) if transition.templated_url
        end

        def add_form_transition(transition)
          raise_abstract('add_form_transition')
        end

        def add_semantics(options)
          @object.each_data_semantic(options) { |semantic| add_semantic(semantic, options) }

          options[:top_level] = false
          @object.each_embedded_semantic(options) { |semantic| add_embedded_semantic(semantic, options) }
        end

        def add_semantic(semantic, options)
          raise_abstract('add_semantic')
        end

        def add_embedded_semantic(semantic, options)
          embedded_element_attributes = {itemscope: 'itemscope', itemtype: semantic.href, itemprop: semantic.name}

          @markup_builder.tag!(element_tag, embedded_element_attributes) do
            case embedded_object = semantic.value
            when Array
              embedded_object.each { |object| add_embedded_object(object, options, semantic)}
            when Crichton::Representor
              add_embedded_object(embedded_object, options)
            else
              logger.warn("Semantic element should be either representor or array! Was #{semantic}")
            end
          end
        end
        
        def add_embedded_object(object, options, semantic)
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
          @markup_builder.span(semantic.value.to_s, itemprop: semantic.name)
        end

        def add_form_transition(transition, method = :post)
          @markup_builder.form({action: transition.url, method: method, name: transition.name}) do
            transition.semantics.values.each do |semantic|
              # If this is a form semantic, pick up its attributes
              if semantic.semantics.any?
                semantic.semantics.values.each { |form_semantic| add_control(form_semantic) }
              else
                add_control(semantic)
              end
            end
            @markup_builder.input({type: :hidden, name: '_method', value: transition.method}) unless transition.safe?
            @markup_builder.input({type: :submit, value: transition.name})
          end
        end

        def add_control_input(semantic, field_type = nil)
          field_type ||= semantic.field_type
          @markup_builder.input({itemprop: semantic.name, type: field_type, name: semantic.name}.merge(semantic.validators))
        end

        def add_control_boolean(semantic)
          add_control_input(semantic, :checkbox)
        end

        def add_control_select(semantic)
          options = semantic.options
          @markup_builder.li do
            if options.is_internal_select?
              @markup_builder.select(name: semantic.name) do
                options.each { |k, v| @markup_builder.option(v, value: k) }
              end
            elsif options.is_external_select?
              opts = options.options
              link_arguments = {value_attribute_name: opts['value_attribute_name']}
              if opts.include?('external_hash')
                description = 'external hash link'
                link_arguments.merge!({type: :hash, text_attribute_name: opts['text_attribute_name'],
                                       href: opts['external_hash']})
              else
                description = 'external list link'
                link_arguments.merge!({type: :list, href: opts['external_list']})
              end
              @markup_builder.a(description, link_arguments)
              @markup_builder.input(type: :text, name: semantic.name)
            end
          end
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
            add_styles
          end
        end

        # @!macro element_tag
        def element_tag
          :ul
        end

      private
        def add_styles
          @markup_builder.tag!(:link, {rel: :stylesheet, href: config.css_uri }) if config.css_uri
          @markup_builder.style do |style|
            style << "*[itemprop]::before {\n  content: attr(itemprop) \": \";\n  text-transform: capitalize;\n}\n"
          end
        end

        def add_semantic(semantic, options)
          @markup_builder.li { super }
        end

        def add_embedded_semantic(semantic, options)
          @markup_builder.li { super }
        end

        def add_embedded_object(object, options, semantic)
          @markup_builder.li do
            case semantic.embed_type(options)
            when :link
              object.as_link(@media_type, options)
            when :embed
              object.as_media_type(@media_type, options)
            end
          end
        end

        def add_link_transition(transition)
          if transition.templated?
            add_form_transition(transition, transition.method)
          elsif transition.url
            @markup_builder.li { super }
          end
        end
        
        # Builds a form control
        def add_form_transition(transition, method = :post)
          @markup_builder.li do
            @markup_builder.form({action: transition.url, method: method}) do
              @markup_builder.ul do
                transition.semantics.values.each do |semantic|
                  if semantic.semantics.any?
                    semantic.semantics.values.each { |form_semantic| add_control(form_semantic) }
                  else
                    add_control(semantic)
                  end
                end
              end
              @markup_builder.input({type: :hidden, name: '_method', value: transition.method }) unless transition.safe?
              @markup_builder.input({type: :submit, value: transition.name})
            end
          end
        end

        def add_control_input(semantic, field_type = nil)
          @markup_builder.li do
            @markup_builder.label({itemprop: semantic.name}) { super }
          end
        end
      end
    end
  end
end
