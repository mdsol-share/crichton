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

      def to_hash
        if @data_type == :no_data
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
        if alps_data.nil?
          data_type = :no_data
        elsif alps_data.is_a?(File)
          # Guess based on file name first
          if alps_data.path.ends_with?('json')
            data_type = :json
          elsif alps_data.path.ends_with?('xml')
            data_type = :xml
          else
            # Guess based on content second
            data_type = alps_data.read(1000).strip.first == '{' ? :json : :xml
            alps_data.rewind
          end
        else
          # Plain string - take content
          data_type = alps_data.strip.first == '{' ? :json : :xml
        end
        data_type
      end

      def json_node_to_hash(node)
        return node unless node.is_a?(Hash)
        result_hash = {}
        node.each do |k, node_element|
          if k == 'ext'
            result_hash.merge!(decode_json_ext(node_element))
          elsif k == 'doc'
            result_hash[k] = json_node_to_hash_doc_element(node_element)
          elsif node_element.is_a?(Array)
            # I'm not quite sure about these. Pluralize is in the ActiveSupport package - but that may be a little
            # heavyweight for what we want here. And adding a linguistics Gem for these may be too heavyweight.
            # So for the cases that I ran into, this seems to work.
            result_hash["#{k}s"] = json_node_to_hash_array_element(node_element)
          else
            result_hash[k] = json_node_to_hash(node_element)
          end
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
          if array_element.is_a?(Hash) && array_element.include?('id')
            array_result_hash[array_element.delete('id')] = json_node_to_hash(array_element)
          else
            array_result_array << json_node_to_hash(array_element)
          end
        end
        return array_result_hash unless array_result_hash.empty?
        array_result_array
      end

      def json_node_to_hash_doc_element(node_element)
        value = node_element['value']
        if node_element.include?('format') && node_element['format'] == 'html'
          value = {"html" => value}
        end
        value
      end

      def decode_json_ext(node_element)
        result_hash = {}
        node_element.each do |ne|
          if ne.include?('href') && ne['href'] == Crichton::ALPS::Serialization::SERIALIZED_OPTIONS_LIST_URL
            if ne.include?('value')
              result_hash['options'] = JSON.parse(ne['value'])
            end
          elsif ne.include?('href') && ne['href'] == Crichton::ALPS::Serialization::SERIALIZED_DATALIST_LIST_URL
            if ne.include?('value')
              result_hash['datalists'] = [] unless result_hash.include?('datalists')
              result_hash['datalists'] << JSON.parse(ne['value'])
            end
          else
            result_hash['ext'] = [] unless result_hash.include?('ext')
            result_hash['ext'] << ne
          end
        end
        result_hash
      end

      def xml_node_to_hash(node)
        # If we are at the root of the document, start the hash
        if node.element?
          result_hash = {}
          xml_node_to_hash_node_attributes(node, result_hash)
          node.children.each do |child|
            result = xml_node_to_hash(child)
            if child.name == 'link'
              # Collect links correctly
              result_hash['links'] ||= {}
              result_hash['links'][child.attributes['rel'].value] = child.attributes['href'].value
            elsif child.name == 'ext'
              decode_xml_ext(result_hash, child)
            elsif child.name == 'doc'
              xml_node_to_hash_unpack_doc(child, result_hash)
            elsif child.name == 'descriptor'
              result_hash['descriptors'] ||= {}
              result_hash['descriptors'][child.attributes['id'].value] = result
            elsif child.name == 'text'
              # Intentionally do nothing
            elsif result_hash[child.name]
              xml_node_to_hash_add_to_result(result_hash, child.name, result)
            else
              result_hash[child.name] = prepare(result)
            end
          end
          result_hash
        else
          return prepare(node.content.to_s)
        end
      end

      def xml_node_to_hash_add_to_result(result_hash, child_name, result)
        if result_hash[child_name].is_a?(Array)
          result_hash[child_name] << prepare(result)
        else
          result_hash[child_name] = [result_hash[child_name], prepare(result)]
        end
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
        elsif child.has_attribute?('href') &&
          child.attribute('href').value == Crichton::ALPS::Serialization::SERIALIZED_DATALIST_LIST_URL
          result_hash['datalists'] = [] unless result_hash.include?('datalists')
          result_hash['datalists'] << JSON.parse(child.attribute('value').value)
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

