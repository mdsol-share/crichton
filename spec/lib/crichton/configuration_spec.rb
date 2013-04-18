require 'spec_helper'

module Crichton
  describe Configuration do
    let(:config) do
      Configuration::ATTRIBUTES.inject({}) do |h, attribute| 
        h["#{attribute}_base_uri"] = "http://#{attribute}.example.org"; h
      end
    end
    let(:configuration) { Configuration.new(config) }

    Configuration::ATTRIBUTES.each do |attribute|
      describe "\##{attribute}_base_uri" do
        it "returns the #{attribute} base URI" do
          configuration.send("#{attribute}_base_uri").should == "http://#{attribute}.example.org"
        end
      end
    end
  end
end
