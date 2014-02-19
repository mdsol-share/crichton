require 'spec_helper'
require 'crichton/configuration'

module Crichton
  describe Configuration do
    let(:configuration) { Configuration.new(example_environment_config) }

    %w(alps deployment discovery documentation crichton_controller).each do |attribute|
      describe "\##{attribute}_base_uri" do
        it "returns the #{attribute} base URI" do
          configuration.send("#{attribute}_base_uri").should == "http://#{attribute}.example.org"
        end
      end
    end

    %w(js css).each do |attribute|
      describe "\##{attribute}_uri" do
        it "returns the #{attribute}_uri as Array" do
          configuration.send("#{attribute}_uri").should be_a(Array)
        end

        it "returns the #{attribute}_uri array with the expected content" do
          configuration.send("#{attribute}_uri").should =~ ["http://example.org/resources/#{attribute}.#{attribute}"]
        end
      end
    end
  end
end
