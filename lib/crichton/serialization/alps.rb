require 'json'
require 'multi_json'

module Crichton
  module Serialization
    module ALPS
      ##
      # ALPS specification attributes that can be serialized.
      ALPS_ATTRIBUTES = %w(id name type href rt)
      
      ##
      # ALPS specification elements that can be serialized.
      ALPS_ELEMENTS = %w(doc ext link)

      ##
      # The ALPS attributes for the descriptor.
      #
      # @param [Hash] options Conditional options.
      # @option options [Hash] :exclude_id <tt>true</tt> to exclude the id from the list of attributes.
      #
      # @return [Hash] The attributes.
      def alps_attributes(options = {})
        @alps_attributes ||= ALPS_ATTRIBUTES.inject({}) do |h, attribute|
          alps_attribute = if attribute == 'name'
            alps_name 
          else
            send(attribute) if respond_to?(attribute)
          end
 
          h[attribute] = alps_attribute if alps_attribute
          h
        end
      end

      ##
      # The ALPS semantic and transition descriptors nested in the descriptor.
      #
      # @return [Array] The descriptors.
      def alps_descriptors
        @alps_descriptors ||= descriptors.map { |descriptor| descriptor.alps_hash(top_level: false) }
      end

      ##
      # The ALPS elements for the descriptor.
      #
      # @return [Hash] The elements.
      def alps_elements
        @alps_elements ||= ALPS_ELEMENTS.inject({}) do |h, element|
          alps_element = send(element) if respond_to?(element)
          
          h.tap do |hash|
            if alps_element
              hash[element] = if element == 'doc'
                if alps_element.is_a?(Hash)
                  format = alps_element.keys.first
                  {'format' => format, 'value' => alps_element[format]}
                else
                  {'value' => alps_element }
                end
              else
                alps_element
              end
            end
          end
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
      def alps_hash(options = {})
        hash = options && options[:top_level] != false ?  {} : {'id' => id}
        hash.merge!(alps_elements.dup)
        hash.merge!(alps_attributes(exlcude_id: true).dup)
        hash['descriptor'] = alps_descriptors unless alps_descriptors.empty?
        
        if options && options[:top_level] != false
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
      # @option options [Symbol] :top_level <tt>false</tt>, if the descriptor should not be wrapped in an 'alps' 
      #   element. Default is <tt>true</tt>.
      # @option options [Symbol] :pretty <tt>true</tt> to pretty-print the json.
      #
      # @return [Hash] The JSON string.
      def to_json(options = {})
        pretty = !!options.delete(:pretty)
        MultiJson.dump(alps_hash(options), :pretty => pretty)
      end
      
      private
      # Access specified name vs. id overloaded name.
      def alps_name
        descriptor_document['name']
      end
    end
  end
end
