require 'json'
require 'addressable/uri'
require 'crichton/helpers'

module Crichton
  module ALPS
    ## 
    # Manages serialization to the Application-Level Profile Semantics (ALPS) specification JSON and XML formats.
    module Serialization
      include Crichton::Helpers::ConfigHelper
      ##
      # ALPS specification attributes that can be serialized.
      ALPS_ATTRIBUTES = %w(id name type href rt)
      
      ##
      # ALPS specification doc element.
      DOC_ELEMENT = 'doc'

      ##
      # ALPS specification ext element.
      EXT_ELEMENT = 'ext'
      
      ##
      # ALPS specification link element.
      LINK_ELEMENT = 'link'

      ##
      # Options element
      OPTIONS_ELEMENT = 'options'

      ##
      # ALPS specification elements that can be serialized.
      ALPS_ELEMENTS = [DOC_ELEMENT, EXT_ELEMENT, OPTIONS_ELEMENT, LINK_ELEMENT]

      ##
      # The ALPS attributes for the descriptor.
      #
      # @return [Hash] The attributes.
      def alps_attributes
        @alps_attributes ||= ALPS_ATTRIBUTES.inject({}) do |hash, attribute|
          alps_attribute = if attribute == 'name'
            alps_name 
          else
            send(attribute) if respond_to?(attribute)
          end

          hash.tap { |h| h[attribute] = alps_attribute if alps_attribute }
        end
      end

      ##
      # The ALPS semantic and transition descriptors nested in the descriptor.
      #
      # @return [Array] The descriptors.
      def alps_descriptors
        if (descriptors = descriptor_document['descriptors']).is_a?(Array)
          descriptors.map { |h| { 'href' => h['href'] } if h['href'].present? }
        else
          @alps_descriptors ||= self.descriptors.map { |descriptor| descriptor.to_alps_hash(top_level: false) }
        end
      end

      ##
      # The ALPS elements for the descriptor.
      #
      # @return [Hash] The elements.
      def alps_elements
        @alps_elements ||= ALPS_ELEMENTS.inject({}) do |hash, element|
          alps_value = send(element) if respond_to?(element)
          next hash unless alps_value

          alps_element = case element
                         when DOC_ELEMENT
                           serialize_doc_element(alps_value)
                         when EXT_ELEMENT
                           convert_ext_element_hrefs(alps_value)
                         when OPTIONS_ELEMENT
                           convert_options_element_to_alps(alps_value)
                         when LINK_ELEMENT
                           unless alps_value.empty?
                             alps_value.values.map do |link|
                                 {'rel' => link.rel, 'href' => absolute_link(link.href, link.rel)}
                               end
                           end
                         end

          hash.tap { |h| element == 'options' ? h.merge!(alps_element) : h[element] = alps_element if alps_element }
        end
      end

      def serialize_doc_element(alps_value)
        if alps_value.is_a?(Hash)
          format = alps_value.keys.first
          {'format' => format, 'value' => alps_value[format]}
        else
          {'value' => alps_value}
        end
      end

      ##
      # Returns an ALPS profile or descriptor as a hash.
      #
      # @param [Hash] options Optional configurations.
      # @option options [Symbol] :top_level <tt>false</tt>, if the descriptor should not be wrapped in an 'alps' 
      #   element. Default is <tt>true</tt>.
      #
      # @return [Hash] The hash.
      def to_alps_hash(options = {})
        hash = {}
        hash.merge!(alps_elements.dup)
        hash.merge!(alps_attributes.dup)
        hash['descriptor'] = alps_descriptors unless alps_descriptors.empty?
        if options[:top_level] != false
          hash.delete('id')
          {'alps' => hash}
        else
          hash
        end
      end

      ##
      # Returns an ALPS profile or descriptor as JSON.
      #
      # @param [Hash] options Optional configurations.
      # @option options [Boolean] :pretty <tt>true</tt> to pretty-print the json.
      #
      # @return [Hash] The JSON string.
      def to_json(options = {})
        MultiJson.dump(to_alps_hash(options), :pretty => !!options.delete(:pretty))
      end

      ##
      # Returns an ALPS profile or descriptor as XML.
      #
      # @param [Hash] options Optional configurations.
      # @option options [Integer] :indent Sets indentation of the tags. Default is 2.
      #
      # @return [Hash] The JSON string.
      def to_xml(options = {})
        require 'builder' unless defined?(::Builder)
        
        options[:indent]  ||= 2
        options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
        
        builder = options[:builder]
        builder.instruct! unless options[:skip_instruct]

        args = options[:top_level] != false ? ['alps'] : ['descriptor', alps_attributes]

        builder.tag!(*args) do
          add_xml_elements(builder)
          add_xml_descriptors(builder)
        end
      end
      
      private
      # Access specified name vs. id overloaded name.
      def alps_name
        descriptor_document['name']
      end

      def add_xml_elements(builder)
        alps_elements.each do |alps_element, properties|
          case alps_element
          when DOC_ELEMENT
            format = {'format' => properties['format']} if properties['format']
            builder.doc(format) { |doc| doc << properties['value'] }
          when EXT_ELEMENT, LINK_ELEMENT
            properties.each { |element_attributes| builder.tag!(alps_element, element_attributes) }
          end
        end
      end

      def absolute_link(orig_link, rel)
        if Addressable::URI.parse(orig_link).absolute?
          orig_link
        else
          "#{rel == 'help' ? config.documentation_base_uri : config.alps_base_uri}/#{orig_link}"
        end
      end

      def convert_ext_element_hrefs(ext_elem)
        if ext_elem.is_a?(Array)
          ext_elem.each {|eae| convert_ext_element_hash_hrefs_and_values(eae) }
        end
        convert_ext_element_hash_hrefs_and_values(ext_elem)
        ext_elem
      end

      SERIALIZED_OPTIONS_LIST_URL = 'http://alps.io/extensions/serialized_options_list'

      def convert_ext_element_hash_hrefs_and_values(ext_elem)
        if ext_elem.is_a?(Hash)
          if ext_elem.include?('href')
            ext_elem['href'] = absolute_link(ext_elem['href'], nil)
          end
          if ext_elem.include?('values')
            ext_elem['value'] = ext_elem.delete('values').to_json
            ext_elem['href'] = SERIALIZED_OPTIONS_LIST_URL unless ext_elem.include?('href')
          end
        end
      end

      def convert_options_element_to_alps(options_elem)
        values = options_elem.is_a?(Hash) ? options_elem : options_elem.descriptor_document
        values.empty? ? {} : {'ext' => convert_ext_element_hrefs([{'values' => values}])}
      end

      def add_xml_descriptors(builder)
        if (descriptors = descriptor_document['descriptors']).is_a?(Array)
          descriptors.each { |h| builder.tag!('descriptor', { href: "\##{h['href']}" }) if h['href'].present? }
        else
          self.descriptors.each do |descriptor|
            descriptor.to_xml({top_level: false, builder: builder, skip_instruct: true})
          end
        end
      end
    end
  end
end
