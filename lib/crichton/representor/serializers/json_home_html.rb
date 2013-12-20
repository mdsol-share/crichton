require 'crichton/representor/serializer'
require 'crichton/helpers'

module Crichton
  module Representor
    ##
    # Manually generates the serialization of a set of entry point resources to an html media type.
    class JsonHomeHtmlSerializer

      ##
      # Returns a ruby object representing a JsonHomeHtml serialization.
      #
      # @param [Set] resources collection of EntryPoint resources
      # @param [Hash] options Optional configurations.
      # @return [Hash] The built representation.
      def self.as_media_type(resources, options)
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
      def self.to_media_type(resources, options = {})
        as_media_type(resources, options)
      end

      private

      def self.configure_markup_builder(options)
        require 'builder' unless defined?(::Builder)

        options[:indent] ||= 0
        options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
        @markup_builder = options[:builder]
      end


      def self.add_head()
        @markup_builder.head { add_styles }
      end

      def self.add_body(resources, options)
        # generate unordered list of resource relations and resource uris hyperlinked
        @markup_builder.body do
          @markup_builder.ul do
            resources.each do |resource|
              @markup_builder.li
              @markup_builder.p
              @markup_builder.b('Rel: ')
              @markup_builder.a(resource.rel, {rel: resource.rel, href: resource.rel})
              @markup_builder.b('  Url:  ')
              @markup_builder.a(resource.url, {rel: resource.url, href: resource.url})
            end
          end
        end
      end

      def self.add_styles
        @markup_builder.tag!(:link, {rel: :stylesheet, href: Crichton.config.css_uri}) if  Crichton.config.css_uri
        @markup_builder.style do |style|
          style << "*[itemprop]::before {\n  content: attr(itemprop) \": \";\n  text-transform: capitalize\n}\n"
        end
      end
    end
  end
end