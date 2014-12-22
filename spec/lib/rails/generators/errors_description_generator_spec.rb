require 'spec_helper'
require "rails/all"
require 'rails/generators'
require 'crichton'
require 'crichton/rails/generators/errors_description_generator'

module Crichton
  describe "ErrorsDescriptionGenerator" do
    let(:resource_name) { "drds_errors" }
    let(:path) { SPECS_TEMP_DIR }
    let(:errors_class_path) { SPECS_TEMP_DIR }
    let(:yaml_filename) {File.join(path, resource_name).concat('.yml')}
    let(:rb_filename) {File.join(path, resource_name).concat('.rb')}


    let(:options) { {force: true, skip: true} }

    after(:all) do
      Object.send(:remove_const, :Rails)
    end

    context 'when specifying values' do
      after(:each) do
        File.delete(yaml_filename) if File.exists?(yaml_filename)
        File.delete(rb_filename) if File.exists?(rb_filename)
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

    context 'when relying on default values' do
      let(:default_errors_filename) { File.join(path, "hyper_error").concat('.yml') }

      # "hyper_error" is the default value of the resource_name argument, and given this testing
      # framework, this is the only reasonable way to relay that information.
      before do
        ErrorsDescriptionGenerator.start([errors_class_path, "hyper_error", path], options)
      end

      after do
        File.delete(default_errors_filename) if File.exists?(default_errors_filename)
      end

      it 'creates a yaml file with the default name' do
        assert_file(default_errors_filename, /HyperError/)
      end
    end
  end
end
