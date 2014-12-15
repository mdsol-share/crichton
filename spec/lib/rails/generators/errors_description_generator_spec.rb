require 'spec_helper'
require "rails/all"
require 'rails/generators'
require 'crichton'
require 'crichton/rails/generators/errors_description_generator'

module Crichton
  describe "ErrorsDescriptionGenerator" do
    let(:resource_name) { "DrdsErrors" }
    let(:path) { SPECS_TEMP_DIR }
    let(:errors_class_path) { 'DrdsErrors' }
    let(:filename) {File.join(path, errors_class_path).concat('.yaml')}
    
    let(:options) { {force: true}}

    after(:each) do
      File.delete(filename) if File.exists?(filename)
    end

    after(:all) do
      Object.send(:remove_const, :Rails)
    end
    
    before do
      ErrorsDescriptionGenerator.start([errors_class_path, resource_name, path],options)
    end

    it "creates a yaml file in the specified location" do
      expect(File.exists?(filename)).to be true
    end

    it "creates a file with references to the errors resource" do
      assert_file(filename, /#{resource_name}/)
    end

    it "creates a file with references to the errors class path" do
      assert_file(filename, /#{errors_class_path}/)
    end

    it "creates a file with all the sections" do
      assert_file(filename, /links:/)
      assert_file(filename, /semantics:/)
      assert_file(filename, /safe:/)
      assert_file(filename, /resources:/)
      assert_file(filename, /http_protocol:/)
    end
  end
end
