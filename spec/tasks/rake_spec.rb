require 'spec_helper'
require 'rake'
require 'lint'
require 'colorize'

describe 'rake crichton.lint' do
  let(:rake_filename) { lint_spec_filename(*@filename) }

  before do
    load_lint_translation_file
    Rake::Task.define_task(:environment)
  end

  before(:each) do
    Rake::Task["crichton:lint"].reenable
  end

  context 'in various modes with and without options' do
    after do
      rake_invocation = @option ? "crichton:lint[#{rake_filename},#{@option}]" : "crichton:lint[#{rake_filename}]"
      capture(:stdout) { Rake.application.invoke_task "#{rake_invocation}" }.should ==
        (@option == 'version' ? capture(:stdout) { Lint.version } : "") <<
          "Linting file:'#{rake_filename}'\n" << (@option ? "Options: #{@option}\n" : "") << @expected_rake_output
    end

    it 'allows users to to validate a single descriptor file' do
      @filename = %w(protocol_section_errors no_entry_points.yml)
      @expected_rake_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
        filename: rake_filename)
    end

    it 'displays empty output when all warnings are suppressed with a warning free result' do
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @expected_rake_output = "In file '#{rake_filename}':\n"
      @option = 'no_warnings'
    end

    it 'returns a version number when invoked with the version option' do
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @expected_rake_output = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http',
        action: 'leviathan-link', filename: rake_filename)
      @option = 'version'
    end
  end

  context 'in strict mode' do
    after do
      capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{rake_filename},strict]" }.should == @result
    end

    it 'returns false when errors are found' do
      @filename = %w(protocol_section_errors missing_protocol_actions.yml)
      @result = "false\n".red << "\n"
    end

    it 'returns true for a clean descriptor file' do
      @filename = %w(protocol_section_errors extraneous_properties.yml)
      @result = "true\n".green << "\n"
    end
  end

  context "using the 'all' option'" do
    before(:all) do
      %x(mkdir api_descriptors)
      %x(cp spec/fixtures/lint_resource_descriptors/missing_sections/* api_descriptors)
    end

    after(:all) do
      %x(rm -rf api_descriptors)
    end

    it 'processes all the files in the config folder' do
      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[all]" }
      %w(nostate_descriptor.yml noprotocols_descriptor.yml nodescriptors_descriptor.yml).all? {
        |file| execution_output.should include(file) }
    end
  end
end
