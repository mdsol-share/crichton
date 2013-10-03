require 'spec_helper'
require 'rake'
require 'lint'
require 'colorize'

describe Lint do
  before do
    load_lint_translation_file
  end

  it "displays empty output when all warnings are suppressed on a warnings only result" do
    filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

    output = "In file '#{filename}':\n"

    content = capture(:stdout) { Lint.validate(filename, {no_warnings: true}) }
    content.should == output
  end

  it 'returns true in strict mode when a clean descriptor file is validated' do
    filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
    Lint.validate(filename, {strict: true}).should be_true
  end

  context "with_strict_mode_errors" do
    after do
      Lint.validate(@filename, {strict: true}).should be_false
    end

    it 'returns false in strict mode when a descriptor file contains errors' do
      @filename = lint_spec_filename('protocol_section_errors', 'missing_protocol_actions.yml')
    end

    it 'a catastrophic error is found' do
      @filename = lint_spec_filename('missing_sections', 'nostate_descriptor.yml')
    end
  end

  it "returns an expected value with the simplest rdlint invocation" do
    filename = lint_spec_filename('protocol_section_errors', 'no_entry_points.yml')

    expected_rdlint_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
                                             filename: filename)

    %x(bundle exec rdlint #{filename}).should == expected_rdlint_output
  end

  it "returns an expected value with an rdlint invocation with the no warning option" do
    filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
    expected_rdlint_output = "In file '#{filename}':\n"
    %x(bundle exec rdlint --no_warnings #{filename}).should == expected_rdlint_output
  end

  it "returns a version number on an rdlint invocation with the version option" do
    filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

    expected_rdlint_output = capture(:stdout) { Lint.version } << expected_output(:warning,
      'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link', filename: filename)

    %x(bundle exec rdlint -v #{filename}).should == expected_rdlint_output
  end

  it 'returns false on an rdlint invocation with the strict option' do
    filename = lint_spec_filename('protocol_section_errors', 'missing_protocol_actions.yml')
    %x(bundle exec rdlint -s #{filename}).should == "false\n".red << "\n"
  end

  it 'returns false on an rdlint invocation with the strict option for multiple files, one clean, one dirty' do
    filename1 = lint_spec_filename('protocol_section_errors', 'missing_protocol_actions.yml')
    filename2 = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
    %x(bundle exec rdlint -s #{filename1} #{filename2}).should == "false\n".red << "\n"
  end

  it 'returns true on an rdlint invocation with the strict option for multiple files, both clean' do
    filename1 = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
    filename2 = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
    %x(bundle exec rdlint -s #{filename1} #{filename2}).should == "true\n".green << "\n"
  end

  describe "rdlint_all_option" do
    # stub does not work in a new shell apparently, so a forced copy to the default api_descriptor dir is made
    before(:all) do
      %x(mkdir api_descriptors)
      %x(cp spec/fixtures/lint_resource_descriptors/missing_sections/* api_descriptors)
    end

    after(:all) do
      %x(rm -rf api_descriptors)
    end

    it 'processes all the files in the config folder' do
      execution_output = %x(bundle exec rdlint -a)
      %w(nostate_descriptor.yml noprotocols_descriptor.yml nodescriptors_descriptor.yml).all? { |file|
        execution_output.should include(file) }
    end
  end

  describe ".rake_work" do
    before(:all) do
      Rake::Task.define_task(:environment)
    end

    before(:each) do
      Rake::Task["crichton:lint"].reenable
    end

    it "allows users to use rake to validate a single descriptor file" do
      filename = lint_spec_filename('protocol_section_errors', 'no_entry_points.yml')

      expected_rake_output = "Linting file:'#{filename}'\n" <<
        expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http', filename: filename)

      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename}]" }
      execution_output.should == expected_rake_output
    end

    it "displays empty output when all warnings are suppressed invoking rake with a warning free result" do
      filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

      expected_rake_output = "Linting file:'#{filename}'\nOptions: no_warnings\n" << "In file '#{filename}':\n"

      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename},no_warnings]" }
      execution_output.should == expected_rake_output
    end

    it "displays empty output when all warnings are suppressed invoking rake with a warning free result" do
      filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

      expected_rake_output = "Linting file:'#{filename}'\nOptions: no_warnings\n" << "In file '#{filename}':\n"

      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename},no_warnings]" }
      execution_output.should == expected_rake_output
    end

    it "returns a version number on an rake invocation with the version option" do
      filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

      expected_rake_output = capture(:stdout) { Lint.version } << "Linting file:'#{filename}'\nOptions: version\n" <<
        expected_output(:warning, 'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link',
                        filename: filename)

      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename},version]" }
      execution_output.should == expected_rake_output
    end

    it 'returns false on an rake invocation with the strict option' do
      filename = lint_spec_filename('protocol_section_errors', 'missing_protocol_actions.yml')
      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename},strict]" }
      execution_output.should == "false\n".red << "\n"
    end

    it 'returns true in strict mode when a clean descriptor file is validated via rake' do
      filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')
      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{filename},strict]" }
      execution_output.should == "true\n".green << "\n"
    end

    describe "rake_all_option" do
      before(:all) do
        %x(mkdir api_descriptors)
        %x(cp spec/fixtures/lint_resource_descriptors/missing_sections/* api_descriptors)
      end

      after(:all) do
        %x(rm -rf api_descriptors)
      end

      it 'processes all the files in the config folder' do
        execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[all]" }
        %w(nostate_descriptor.yml noprotocols_descriptor.yml nodescriptors_descriptor.yml).all? { |file|
          execution_output.should include(file) }
      end
    end
  end
end
