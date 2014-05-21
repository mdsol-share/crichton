require 'spec_helper'
require 'rake'
require 'crichton'
require 'crichton/lint'

describe 'rake crichton.lint' do
  let(:rake_filename) { create_drds_file(@descriptor, @filename) }

  before(:all) do
    @filename = 'drds_lint'
    load lint_rake_path
  end

  before do
    Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
  end

  before do
    load_lint_translation_file
    Rake::Task.define_task(:environment)
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
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['list'].except!('entry_point')
      end
      @expected_rake_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
        filename: rake_filename, section: :protocols, sub_header: :error)
    end

    it 'reports empty output when all warnings are suppressed with a warning free result' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
      end
      @expected_rake_output = "In file '#{rake_filename}':\n"
      @option = 'no_warnings'
    end

    it 'reports a version number when invoked with the version option' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
      end
      @expected_rake_output = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http',
        action: 'leviathan-link', filename: rake_filename, section: :protocols, sub_header: :warning)
      @option = 'version'
    end
  end

  context 'with the --strict option' do
    after do
      expect(capture(:stdout) { Rake.application.invoke_task "crichton:lint[#{rake_filename},strict]" }).to eq(@result)
    end

    it 'reports false when errors are found' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http'].except!('list')
      end
      @result = %Q(#{"false\n".red}\n)
    end

    it 'reports true for a clean descriptor file' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
      end
      @result = %Q(#{"true\n".green}\n)
    end
  end

  context 'with the --all option' do
    it 'processes all the files in the config folder' do
      Crichton.stub(:descriptor_location).and_return(SPECS_TEMP_DIR)
      descriptor = new_drds_descriptor.tap { |document| document.except!('protocols') }
      create_drds_file(descriptor, 'noprotocols.yml')
      descriptor = normalized_drds_descriptor.tap { |document| document.except!('descriptors') }
      create_drds_file(descriptor, 'nodescriptors.yml')
      execution_output = capture(:stdout) { Rake.application.invoke_task "crichton:lint[all]" }
      all_files_processed = %w(noprotocols.yml nodescriptors.yml).all? { |f| execution_output.include?(f) }
      expect(all_files_processed).to be_true
    end
  end
end
