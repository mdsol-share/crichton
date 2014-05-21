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
          expect(deserializer.to_hash.keys).to be_empty
        end

        it 'handles nil XML data' do
          deserializer = Deserialization.new(nil)
          expect(deserializer.to_hash.keys).to be_empty
        end

        it 'deserializes XML data' do
          deserializer = Deserialization.new(alps_xml_opened_file)
          expect(deserializer.to_hash.keys).to eq(['doc', 'ext', 'links', 'descriptors'])
        end

        it 'deserializes JSON data' do
          deserializer = Deserialization.new(alps_json_data)
          expect(deserializer.to_hash.keys).to eq(['doc', 'links', 'descriptors'])
        end

        it 'deserializes a JSON DRD' do
          deserializer = Deserialization.new(alps_json_data)
          expect(deserializer.to_hash.keys).to eq(['doc', 'links', 'descriptors'])
        end

        it 'deserializes a XML DRD' do
          deserializer = Deserialization.new(alps_xml_data)
          expect(deserializer.to_hash.keys).to eq(['doc', 'links', 'descriptors'])
        end

        it 'deserializes an opened JSON file continaing a DRD' do
          deserializer = Deserialization.new(alps_json_opened_file)
          expect(deserializer.to_hash.keys).to eq(['doc', 'links', 'descriptors'])
        end

        it 'deserializes an opened JSON file continaing a DRD with a unhelpful filename' do
          deserializer = Deserialization.new(alps_json_opened_file_with_bad_filename)
          expect(deserializer.to_hash.keys.sort).to eq(['doc', 'links', 'descriptors', 'ext'].sort)
        end

        it 'deserializes an opened XML file continaing a DRD with a unhelpful filename' do
          deserializer = Deserialization.new(alps_xml_opened_file_with_bad_filename)
          expect(deserializer.to_hash.keys.sort).to eq(['doc', 'links', 'descriptors', 'ext' ].sort)
        end
      end

      describe '#alps_to_hash' do
        it 'populates the link section properly' do
          deserializer = Deserialization.new(alps_xml_opened_file)
          deserialized_hash = deserializer.to_hash
          expect(deserialized_hash).to include({
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
