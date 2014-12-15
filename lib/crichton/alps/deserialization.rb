require 'nokogiri'

#Taken from https://gist.github.com/dimus/335286 and modified

module Crichton
  module ALPS
    ##
    # Manages serialization to the Application-Level Profile Semantics (ALPS) specification JSON and XML formats.
    class Deserialization
      def initialize(alps_data, data_type = nil)
        @alps_data = alps_data
        @data_type = data_type || guess_alps_data_type(@alps_data)
      end

      def to_hash #HACK! : Memoization is a stupid substitute for not mutating
        @to_hash ||= if @data_type == :no_data
          {}
        elsif @data_type == :xml
          alps_xml_to_hash(@alps_data)
        else
          alps_json_to_hash(@alps_data)
        end
      end

      def alps_xml_to_hash(alps_data)
        xml_data = Nokogiri::XML(alps_data)
        xml_node_to_hash(xml_data.root)
      end

      def alps_json_to_hash(alps_data)
        json_data = JSON.load(alps_data)
        raw_node = json_node_to_hash(json_data)
        raw_node['alps']
      end

      private
      def guess_alps_data_type(alps_data)
        data_type = nil
        infer_json_from_text = ->(text) { text.strip.first == '{' ? :json : :xml }
        if alps_data.is_a?(File)
          [:json, :xml].map { |ext| data_type = ext if alps_data.path.ends_with?(ext.to_s) }

          data_type = infer_json_from_text.call( alps_data.read(1000) ) unless data_type
          alps_data.rewind
        elsif alps_data.kind_of?(String)
          data_type = infer_json_from_text.call( alps_data ) unless alps_data.empty?
        end
        data_type || :no_data
      end

      def json_node_to_hash(node)
        return node unless node.is_a?(Hash)
        result_hash = {}

        switch_map = {}
        switch_map["ext"] = ->(k,n) { decode_json_ext(n) }
        switch_map["doc"] = ->(k,n) { {k => json_node_to_hash_doc_element(n) } }
        ["link", "descriptor"].map do |key|
          switch_map[key] = ->(k,n) { {"#{k}s" => json_node_to_hash_array_element(n) } }
        end
        ["alps", "rel", "href", "type", "rt"].map do |key|
          switch_map[key] = ->(k,n) { {k => json_node_to_hash(n) } }
        end

        node.each do |k, node_element|
          result_hash.merge!( switch_map[k].call(k, node_element ) )
        end
        result_hash
      end

      def json_node_to_hash_array_element(node_element)
        # We can have either a data structure that uses IDs and then is put into a hash or lacking the IDs we end
        # up having an array. The loop can handle both types and skips special logic to beforehand determine what
        # kind of data it is.
        array_result_hash = {}
        array_result_array = []
        node_element.each do |array_element|
          if array_element.is_a?(Hash)
            array_result_hash[array_element.delete('id')] = json_node_to_hash(array_element)
          else
            array_result_array << json_node_to_hash(array_element)
          end
        end
        array_result_hash.empty? ? array_result_array : array_result_hash
      end

      def json_node_to_hash_doc_element(node_element)
        value = node_element['value']
        node_element.include?('format') && node_element['format'] == 'html' ? {"html" => value} : value
      end

      def decode_json_ext(node_element)
        result_hash = {}
        node_element.each do |ne|
          # This seems crazy!
          if ne.include?('href') && ne['href'] == Crichton::ALPS::Serialization::SERIALIZED_OPTIONS_LIST_URL
            result_hash['options'] = JSON.parse(ne['value']) if ne.include?('value')
          else
            # This case should handle unknown ext elements somewhat sanely - but ideally it should never be used.
            result_hash['ext'] = [] unless result_hash.include?('ext')
            result_hash['ext'] << ne
          end
        end
        result_hash
      end

      def xml_node_to_hash(node)
        result_hash = {}
        xml_node_to_hash_node_attributes(node, result_hash)
        node.children.each do |child|
          if child.name == 'link'
            # Collect links correctly
            result_hash['links'] ||= {}
            result_hash['links'][child.attributes['rel'].value] = child.attributes['href'].value
          elsif child.name == 'ext'
            decode_xml_ext(result_hash, child)
          elsif child.name == 'doc'
            xml_node_to_hash_unpack_doc(child, result_hash)
          elsif child.name == 'descriptor'
            decendent = xml_node_to_hash(child)
            if child.attributes['id'].present?
              result_hash['descriptors'] ||= {}
              result_hash['descriptors'][child.attributes['id'].value] = decendent
            else
              result_hash['descriptors'] ||= []
              result_hash['descriptors'] << decendent
            end
          elsif child.name == 'text'
            # Intentionally do nothing
          else
            raise NameError, "ALPS doesn't specify how to parse a #{child.name}"
          end
        end
        result_hash
      end

      def xml_node_to_hash_unpack_doc(child, result_hash)
        # Unpack the doc element correctly
        if child.attributes.include?('format') && child.attributes['format'].value == 'html'
          result_hash['doc'] = {"html" => child.inner_html.strip}
        else
          result_hash['doc'] = child.text.strip
        end
      end

      def xml_node_to_hash_node_attributes(node, result_hash)
        node.attributes.keys.each do |key|
          unless node.name == 'descriptor' && key == 'id'
            result_hash[node.attributes[key].name] = prepare(node.attributes[key].value)
          end
        end
      end

      def decode_xml_ext(result_hash, child)
        if child.has_attribute?('href') &&
          child.attribute('href').value == Crichton::ALPS::Serialization::SERIALIZED_OPTIONS_LIST_URL
          if child.has_attribute?('value')
            result_hash['options'] = JSON.parse(child.attribute('value').value)
          end
        else
          result_hash['ext'] = [] unless result_hash.include?('ext')
          result_hash['ext'] << child.attributes
        end
      end

      def prepare(data)
        data.class == String && data.to_i.to_s == data ? data.to_i : data
      end
    end
  end
end
