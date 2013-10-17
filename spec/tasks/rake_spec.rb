require 'spec_helper'
require 'rake'
require 'crichton'
require 'crichton/lint'
require 'colorize'

describe 'rake crichton.lint' do
  let(:rake_filename) { lint_spec_filename(*@filename) }

  before do
    load_lint_translation_file
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    Rake::Task['crichton:lint'].reenable
  end

  context 'in various modes with and without options' do
    after do
      rake_invocation = @option ? "crichton:lint[#{rake_filename},#{@option}]" : "crichton:lint[#{rake_filename}]"
      capture(:stdout) { Rake.application.invoke_task "#{rake_invocation}" }.should ==
        (@option == 'version' ? capture(:stdout) { Crichton::Lint.version } : "") <<
          "Linting file:'#{rake_filename}'\n#{(@option ? "Options: #{@option}\n" : "")}#{@expected_rake_output}"
    end

    it 'allows users to to validate a single descriptor file' do
      @filename = %w(protocol_section_errors no_entry_points.yml)
      @expected_rake_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
        filename: rake_filename)
    end

    it 'reports empty output when all warnings are suppressed with a warning free result' do
      Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return("<alps></alps>")
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @expected_rake_output = "In file '#{rake_filename}':\n"
      @option = 'no_warnings'
    end

    it 'reports a version number when invoked with the version option' do
      Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return("<alps></alps>")
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @expected_rake_output = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http',
        action: 'leviathan-link', filename: rake_filename)
      @option = 'version'
    end
  end

  context 'with the --strict option' do
    after do
      capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{rake_filename},strict]" }.should == @result
    end

    it 'reports false when errors are found' do
      @filename = %w(protocol_section_errors missing_protocol_actions.yml)
      @result = %Q(#{"false\n".red}\n)
    end

    it 'reports true for a clean descriptor file' do
      Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return("<alps></alps>")
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @result = %Q(#{"true\n".green}\n)
    end
  end

  context 'with the --all option' do
    before do
      build_dir_for_lint_rspec('api_descriptors', 'fixtures/lint_resource_descriptors/missing_sections')
    end

    after do
      FileUtils.rm_rf('api_descriptors')
      Crichton.stub(:descriptor_location).and_return('test_directory')
    end

    it 'processes all the files in the config folder' do
      Crichton.stub(:descriptor_location).and_return('api_descriptors')
      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[all]" }
      all_files_processed = %w(nostate_descriptor.yml noprotocols_descriptor.yml
        nodescriptors_descriptor.yml).all? do |file|
        execution_output.include?(file)
      end

      all_files_processed.should be_true
    end
  end
end
