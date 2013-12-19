require 'spec_helper'
require 'crichton/configuration'

module Crichton
  describe Configuration do
    let(:configuration) { Configuration.new(example_environment_config) }

    %w(alps deployment discovery documentation).each do |attribute|
      describe "\##{attribute}_base_uri" do
        it "returns the #{attribute} base URI" do
          configuration.send("#{attribute}_base_uri").should == "http://#{attribute}.example.org"
        end
      end
    end

    %w(css).each do |attribute|
      describe "\##{attribute}_uri" do
        it "returns the #{attribute} uri" do
          configuration.send("#{attribute}_uri").should == "http://example.org/resources/#{attribute}.#{attribute}"
        end
      end
    end
  end
end
