require 'spec_helper'
require 'crichton/alps/deserialization'

module Crichton
  module ALPS 
    describe Deserialization do
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
