require 'spec_helper'
require 'crichton/alps/deserialization'

module Crichton
  module ALPS 
    describe Deserialization do
      describe '.new' do
        after do
          # Rewind file so the next user can read it
          alps_xml_opened_file.rewind
          alps_json_opened_file.rewind
        end

        it 'handles empty XML data' do
          deserializer = Deserialization.new('')
          deserializer.to_hash.keys.should == []
        end

        it 'handles nil XML data' do
          deserializer = Deserialization.new(nil)
          deserializer.to_hash.keys.should == []
        end

        it 'deserializes XML data' do
          deserializer = Deserialization.new(alps_xml_opened_file)
          deserializer.to_hash.keys.should == ['doc', 'ext', 'links', 'descriptors', 'datalists']
        end

        it 'deserializes JSON data' do
          deserializer = Deserialization.new(alps_json_data)
          deserializer.to_hash.keys.should == ['doc', 'links', 'descriptors']
        end

        it 'deserializes a JSON DRD' do
          deserializer = Deserialization.new(alps_json_data)
          deserializer.to_hash.keys.should == ['doc', 'links', 'descriptors']
        end

        it 'deserializes a XML DRD' do
          deserializer = Deserialization.new(alps_xml_data)
          deserializer.to_hash.keys.should == ['doc', 'links', 'descriptors']
        end

        it 'deserializes an opened JSON file continaing a DRD' do
          deserializer = Deserialization.new(alps_json_opened_file)
          deserializer.to_hash.keys.should == ['doc', 'links', 'descriptors']
        end

        it 'deserializes an opened JSON file continaing a DRD with a unhelpful filename' do
          deserializer = Deserialization.new(alps_json_opened_file_with_bad_filename)
          deserializer.to_hash.keys.should == ['doc', 'links', 'datalists', 'descriptors']
        end

        it 'deserializes an opened XML file continaing a DRD with a unhelpful filename' do
          deserializer = Deserialization.new(alps_xml_opened_file_with_bad_filename)
          deserializer.to_hash.keys.should == ['doc', 'links', 'descriptors', 'datalists']
        end
      end

      describe '#alps_to_hash' do
        it 'populates the link section properly' do
          deserializer = Deserialization.new(alps_xml_opened_file)
          deserialized_hash = deserializer.to_hash
          deserialized_hash.should include({
            "links" => {
              "self" => "http://alps.example.com/Leviathans",
              "help" => "http://docs.example.org/Things/Leviathans"
              }
            })
        end
      end
    end
  end
end
