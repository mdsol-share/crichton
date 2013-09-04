require 'spec_helper'

module Crichton
  module ALPS 
    describe Deserialization do
      describe '.init' do
        it 'deserializes XML data' do
          deserializer = Deserialization.new(alps_xml_string)
          deserializer.to_hash.keys.should == ["text", "doc", "ext", "links", "descriptors"]
        end

        it 'deserializes JSON data' do
          alps_xml_string.rewind
          xmldeserializer = Crichton::ALPS::Deserialization.new(alps_xml_string.read)
          alps_xml_string.rewind
          deserializer = Deserialization.new("{\"alps\": #{xmldeserializer.to_json}}")
          deserializer.to_hash.keys.should == ["texts", "doc", "ext", "links", "descriptors"]
        end
      end

      describe '#alps_to_hash' do
        it 'populates the link section properly' do
          deserializer = Deserialization.new(alps_xml_string)
          deserialized_hash = deserializer.to_hash
          deserialized_hash.should include({
            "links" => {
              "self" => "alps_base/Leviathans",
              "help" => "documentation_base/Things/Leviathans"
              }
            })
        end
      end
    end
  end
end
