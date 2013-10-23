require 'crichton/descriptor/base'
require 'addressable/uri'

module Crichton
  module Descriptor
    ##
    # Manages link information associated with a descriptor.
    class Link < Base

      # @param [Hash] resource_descriptor The parent resource descriptor instance.                                                              # 
      # @param [String, Symbol] rel The relationship of the link.
      # @param [String, Symbol] href The href of the associated link.
      def initialize(resource_descriptor, rel, href)
        descriptor_document = {'rel' => rel.to_s, 'href' => href.to_s}
        super(resource_descriptor, descriptor_document, rel)
      end
      
      alias :rel :name
      alias :url :href
      
      ##
      # The attributes of the link.
      def attributes
        {rel: rel, href: href}
      end

      def templated?
        false
      end

      def absolute_href
        if href.nil? || Addressable::URI.parse(href).absolute?
          href
        else
          "#{rel == 'help' ? config.documentation_base_uri : config.alps_base_uri}/#{href}"
        end
      end
    end
  end
end
