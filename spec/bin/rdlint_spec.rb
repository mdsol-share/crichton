require 'spec_helper'
require 'rake'
require 'crichton/lint'
require 'colorize'

describe 'rdlint' do
  let(:filename) { lint_spec_filename(*@filename) }
  let(:filenames) { "#{lint_spec_filename(*@filename1)} #{lint_spec_filename(*@filename2)}" }
  let(:false_string) {"false\n"}
  let(:no_file_specified) { "No file(s) specified for lint." }

  before do
    load_lint_translation_file
  end

  context 'in various modes with and without options' do
    after do
      %x(bundle exec rdlint #{@option} #{filename}).should == @expected_rdlint_output
    end

    it 'reports an expected value with the simplest invocation' do
      @filename = %w(protocol_section_errors no_entry_points.yml)
      @expected_rdlint_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
        filename: filename, section: :protocols, sub_header: :error)
      @option = ''
    end

    it 'displays empty output when all warnings are suppressed on a warnings only result' do
      @filename = %w(protocol_section_errors properties_failures.yml)
      @expected_rdlint_output = "In file '#{filename}':\n"
      @option = '-w'
    end

    it 'reports an expected value with the no warning option' do
      @filename = %w(protocol_section_errors properties_failures.yml)
      @expected_rdlint_output = "In file '#{filename}':\n"
      @option = '-w'
    end

    it 'reports a version number with the version option' do
      @filename = %w(protocol_section_errors properties_failures.yml)
      @expected_rdlint_output = capture(:stdout) { Crichton::Lint.version } << expected_output(:warning,
        'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link', filename: filename,
        section: :protocols, sub_header: :warning)
      @option = '-v'
    end

  end

  context 'when a user does not specify a filename' do
    it 'reports an error with no options' do
      %x(bundle exec rdlint).should include(no_file_specified)
    end

    it 'reports an error with the --no_warnings option' do
      %x(bundle exec rdlint -w).should include(no_file_specified)
    end

    it 'reports an error with the --strict option' do
      %x(bundle exec rdlint -s).should include(no_file_specified)
    end

    it 'reports an error with the --version option' do
      %x(bundle exec rdlint -v).should include(no_file_specified)
    end
  end

  context 'when loading an invalid file' do
    it 'reports a load error' do
      @expected_rdlint_output = build_colorized_lint_output(:error, 'catastrophic.cant_load_file',
        exception_message: 'No such file or directory - /xxx/yyy') << "\n"
      %x(bundle exec rdlint /xxx/yyy).should == @expected_rdlint_output
    end
  end

  context 'with the --strict option' do
    it 'reports false when errors occur' do
      @filename = %w(protocol_section_errors missing_protocol_actions.yml)
      %x(bundle exec rdlint -s #{filename}).should == %Q(#{false_string.red}\n)
    end

    context 'with multiple files' do
      after do
        %x(bundle exec rdlint -s #{filenames}).should == %Q(#{@output}\n)
      end

      it 'reports false when one clean is clean, one dirty' do
        @filename1 = %w(protocol_section_errors missing_protocol_actions.yml)
        @filename2 = %w(protocol_section_errors extraneous_properties.yml)
        @output = "false\n".red
      end

      it 'reports true all are clean' do
        @filename1 = %w(protocol_section_errors properties_failures.yml)
        @filename2 = %w(protocol_section_errors properties_failures.yml)
        @output = "true\n".green
      end
    end
  end

  context 'with the --all option' do
    # stub does not work in a new shell apparently, so a forced copy to the default api_descriptor dir is made
    before(:all) do
      build_dir_for_lint_rspec('api_descriptors', 'fixtures/lint_resource_descriptors/missing_sections')
    end

    after(:all) do
      FileUtils.rm_rf('api_descriptors')
    end

    it 'processes all the files in the config folder' do
      execution_output = %x(bundle exec rdlint -a)
      all_files_processed = %w(nostate_descriptor.yml noprotocols_descriptor.yml
        nodescriptors_descriptor.yml).all? do |file|
        execution_output.include?(file)
      end

      all_files_processed.should be_true
    end
  end
end
