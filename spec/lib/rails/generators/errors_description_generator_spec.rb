require 'spec_helper'
require "rails/all"
require 'rails/generators'
require 'crichton'
require 'crichton/rails/generators/errors_description_generator'

module Crichton
  describe "ErrorsDescriptionGenerator" do
    let(:resource_name) { "DrdsErrors" }
    let(:path) { SPECS_TEMP_DIR }
    let(:errors_class_path) { SPECS_TEMP_DIR }
    let(:yaml_filename) {File.join(path, resource_name).concat('.yaml')}
    let(:rb_filename) {File.join(path, resource_name).concat('.rb')}
    
    
    let(:options) { {force: true, skip: true} }

    after(:each) do
      File.delete(yaml_filename) if File.exists?(yaml_filename)
      File.delete(rb_filename) if File.exists?(rb_filename)
    end

    after(:all) do
      Object.send(:remove_const, :Rails)
    end
    
    before do
      ErrorsDescriptionGenerator.start([errors_class_path, resource_name, path],options)
    end

    it "creates yaml and rb files in the specified location" do
      expect(File.exists?(yaml_filename)).to be true
      expect(File.exists?(rb_filename)).to be true
    end

    it "creates a file with references to the errors resource" do
      assert_file(yaml_filename, /#{resource_name}/)
    end

    it "creates a file with references to the errors class path" do
      assert_file(rb_filename, /represents :#{resource_name}/)
    end

    it "creates a file with all the sections" do
      assert_file(yaml_filename, /links:/)
      assert_file(yaml_filename, /semantics:/)
      assert_file(yaml_filename, /safe:/)
      assert_file(yaml_filename, /resources:/)
      assert_file(yaml_filename, /http_protocol:/)
    end
  end
end
