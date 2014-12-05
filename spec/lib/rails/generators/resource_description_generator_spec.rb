require 'spec_helper'

def assert_file(relative_path, regexp)
 # absolute = File.expand_path(relative, destination_root)
  expect(File.exists?(relative_path)).to be true

  read = File.read(relative_path)

  expect(read).to match(regexp)
end

module Crichton
  describe "ResourceDescriptionGenerator" do
    let(:resource_name) { "my_resource" }
    let(:collection_name) { "my_collection" }
    let(:path) { SPECS_TEMP_DIR }
    let(:filename) {File.join(path, collection_name).concat('.yaml')}
    let(:options) { {force: true}}

    before(:all) do
      require "rails/all"
      require 'rails/generators'
      require 'crichton'
      require 'crichton/rails/generators/resource_description_generator'
    end

    after(:each) do
      File.delete(filename) if File.exists?(filename)
    end

    after(:all) do
      Object.send(:remove_const, :Rails)
    end

    it "creates a yaml file in the specified location" do
      ResourceDescriptionGenerator.start([resource_name, collection_name, path],options)
      expect(File.exists?(filename)).to be true
    end

    it "creates a file with references to the resource" do
      ResourceDescriptionGenerator.start([resource_name, collection_name, path],options)
      assert_file(filename, /#{resource_name}/)
    end

    it "creates a file with references to the collection" do
      ResourceDescriptionGenerator.start([resource_name, collection_name, path],options)
      assert_file(filename, /#{collection_name}/)
    end

    it "creates a file with all the sections" do
      ResourceDescriptionGenerator.start([resource_name, collection_name, path],options)
      assert_file(filename, /links:/)
      assert_file(filename, /semantics:/)
      assert_file(filename, /extensions:/)
      assert_file(filename, /safe:/)
      assert_file(filename, /idempotent:/)
      assert_file(filename, /unsafe:/)
      assert_file(filename, /resources:/)
      assert_file(filename, /media_types:/)
      assert_file(filename, /http_protocol:/)
      assert_file(filename, /routes:/)
    end

  end
end
