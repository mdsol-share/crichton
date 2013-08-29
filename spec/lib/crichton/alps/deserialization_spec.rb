require 'spec_helper'

module Crichton
  module ALPS 
    describe Deserialization do
      describe '#alps_to_hash' do
        it 'populates the link section properly' do
          deserializer = Deserialization.new(alps_xml_string)
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
