require 'crichton/representor/serializer'
require 'crichton/helpers'

module Crichton
  module Representor
    ##
    # Manually generates the serialization of a set of entry point resources to an html media type.
    class JsonHomeHtmlSerializer
      include Crichton::Helpers::ConfigHelper

      ##
      # Returns a ruby object representing a JsonHomeHtml serialization.
      #
      # @param [Set] resources collection of EntryPoint resources
      # @param [Hash] options Optional configurations.
      # @return [Hash] The built representation.
      def as_media_type(resources, options)
        options ||= {}
        configure_markup_builder(options)

        @markup_builder.declare!(:DOCTYPE, :html)
        @markup_builder.tag!(:html, xmlns: 'http://www.w3.org/1999/xhtml') do
          add_head
          add_body(resources, options)
        end
      end

      ##
      # Returns a json object representing a JsonHomeHtml serialization.
      #
      # @param [Set] resources collection of EntryPoint resources
      # @param [Hash] options Optional configurations.
      # @return [Hash] The built representation.
      def to_media_type(resources, options = {})
        as_media_type(resources, options)
      end

      private
      def configure_markup_builder(options)
        require 'builder' unless defined?(::Builder)

        options[:indent] ||= 2
        options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
        @markup_builder = options[:builder]
      end

      def add_head()
        @markup_builder.head { add_styles }
      end

      def add_body(resources, options)
        # generate unordered list of resource relations and resource uris hyperlinked
        @markup_builder.body do
          if microdata?(options)
            resources.each { |resource| resource_rel_links(resource) }
          else
            add_styled_list(resources)
          end
        end
      end

      def add_styles
        config.css_uri.each do |url|
          @markup_builder.tag!(:link, {rel: :stylesheet, href: url })
        end
        @markup_builder.style { |style| style << xhtml_css }
      end

      def add_styled_list(resources)
        @markup_builder.ul do
          resources.each do |resource|
            @markup_builder.li { resource_rel_links(resource) }
          end
        end
      end

      def resource_rel_links(resource)
        @markup_builder.p
        @markup_builder.b('Rel: ')
        @markup_builder.a(resource.rel, {rel: resource.rel, href: resource.rel})
        @markup_builder.b('  Url:  ')
        @markup_builder.a(resource.url, {rel: resource.url, href: resource.url})
      end

      def microdata?(options)
        options && options[:semantics] == :microdata
      end

      def xhtml_css
        File.read(File.join(File.dirname(__FILE__), 'html/xhtml.css'))
      end
    end
  end
end
