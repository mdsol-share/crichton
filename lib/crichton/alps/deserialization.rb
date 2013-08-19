require 'nokogiri'

#Taken from https://gist.github.com/dimus/335286 and modified

module Crichton
  module ALPS
    ##
    # Manages serialization to the Application-Level Profile Semantics (ALPS) specification JSON and XML formats.
    class Deserialization
      def self.alps_xml_to_hash(alps_data)
        xml_data = Nokogiri::XML(alps_data)
        xml_node_to_hash(xml_data.root)
      end

      def self.xml_node_to_hash(node)
            # If we are at the root of the document, start the hash
            if node.element?
              result_hash = {}
              if node.attributes != {}
                node.attributes.keys.each do |key|
                  unless (node.name == 'descriptor') && (key == 'id')
                    result_hash[node.attributes[key].name] = prepare(node.attributes[key].value)
                  end
                end
              end
              if node.children.size > 0
                node.children.each do |child|
                  result = xml_node_to_hash(child)

                  if child.name == "text"
                    unless child.next_sibling || child.previous_sibling
                      return prepare(result)
                    end
                  elsif child.name == 'link'
                    # Collect links correctly
                    result_hash['links'] = {} unless result_hash.include?('links')
                    result_hash['links'][child.attributes['rel'].value] = child.attributes['href'].value
                  elsif child.name == 'doc'
                    # Unpack the doc element correctly
                    result_hash['doc'] = child.text.strip
                  elsif child.name == 'descriptor'
                    result_hash['descriptors'] = {} unless result_hash.include?('descriptors')
                    result_hash['descriptors'][child.attributes['id'].value] = result
                  elsif result_hash[child.name]
                    if result_hash[child.name].is_a?(Object::Array)
                      result_hash[child.name] << prepare(result)
                    else
                      result_hash[child.name] = [result_hash[child.name]] << prepare(result)
                    end
                  else
                    result_hash[child.name] = prepare(result)
                  end
                end

                return result_hash
              else
                return result_hash
              end
            else
              return prepare(node.content.to_s)
            end
          end

          def self.prepare(data)
            (data.class == String && data.to_i.to_s == data) ? data.to_i : data
          end

        #def self.to_struct(struct_name)
        #    Struct.new(struct_name,*keys).new(*values)
        #end
    end
  end
end

