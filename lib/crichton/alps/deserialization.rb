require 'nokogiri'

#Taken from https://gist.github.com/dimus/335286 and modified

module Crichton
  module ALPS
    ##
    # Manages serialization to the Application-Level Profile Semantics (ALPS) specification JSON and XML formats.
    class Deserialization
      def initialize(alps_data, data_type = nil)
        if data_type.nil?
          if alps_data.is_a?(File)
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
        end
        if data_type == :xml
          @hash = alps_xml_to_hash(alps_data)
        else
          @hash = alps_json_to_hash(alps_data)
        end
      end

      def to_hash
        @hash
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
      def json_node_to_hash(node)
        unless node.is_a?(Hash)
          return node
        end
        result_hash = {}
        node.each do |k,v|
          if v.is_a?(Array)
            a_result_hash = {}
            a_result_array = []
            v.each do |ae|
              if ae.is_a?(Hash) && ae.include?('id')
                a_result_hash[ae.delete('id')] = json_node_to_hash(ae)
              else
                a_result_array << json_node_to_hash(ae)
              end
            end
            # I'm not quite sure about these. Pluralize is in the ActiveSupport package - but that may be a little
            # heavyweight for what we want here. And adding a linguistics Gem for these may be too heavyweight.
            # So for the cases that I ran into, this seems to work.
            result_hash["#{k}s"] = a_result_hash unless a_result_hash.empty?
            result_hash["#{k}s"] = a_result_array unless a_result_array.empty?
          else
            result_hash[k] = json_node_to_hash(v)
          end
        end
        result_hash
      end

      def xml_node_to_hash(node)
        # If we are at the root of the document, start the hash
        if node.element?
          result_hash = {}
          node.attributes.keys.each do |key|
            unless node.name == 'descriptor' && key == 'id'
              result_hash[node.attributes[key].name] = prepare(node.attributes[key].value)
            end
          end
          node.children.each do |child|
            result = xml_node_to_hash(child)
            if child.name == 'link'
              # Collect links correctly
              result_hash['links'] ||= {}
              result_hash['links'][child.attributes['rel'].value] = child.attributes['href'].value
            elsif child.name == 'doc'
              # Unpack the doc element correctly
              result_hash['doc'] = child.text.strip
            elsif child.name == 'descriptor'
              result_hash['descriptors'] ||= {}
              result_hash['descriptors'][child.attributes['id'].value] = result
            elsif result_hash[child.name]
              if result_hash[child.name].is_a?(Array)
                result_hash[child.name] << prepare(result)
              else
                result_hash[child.name] = [result_hash[child.name], prepare(result)]
              end
            else
              result_hash[child.name] = prepare(result)
            end
          end
          result_hash
        else
          return prepare(node.content.to_s)
        end
      end

      def prepare(data)
        data.class == String && data.to_i.to_s == data ? data.to_i : data
      end
    end
  end
end

