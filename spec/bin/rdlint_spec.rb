require 'spec_helper'
require 'rake'
require 'crichton/lint'
require 'colorize'

describe 'rdlint' do
  let(:filename) { create_drds_file(@descriptor, @filename) }
  let(:false_string) {"false\n"}
  let(:no_file_specified) { "No file(s) specified for lint." }

  before(:all) do
    @filename = 'drds_lint.yml'
  end

  after(:all) do
    FileUtils.rm_rf('api_descriptors')
  end

  before do
    load_lint_translation_file
  end

  context 'in various modes with and without options' do
    before(:all) do
      eds = Crichton::ExternalDocumentStore.new('api_descriptors/external_documents_store')
      Support::ALPSSchema::StubUrls.each do |url, body|
        stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
        eds.download_link_and_store_in_document_store(url)
      end
    end

    after do
      expect(%x(bundle exec rdlint #{@option} #{filename})).to eq(@expected_rdlint_output)
    end

    it 'reports an expected value with the simplest invocation' do
      @descriptor = new_drds_descriptor.tap { |doc| doc['protocols']['http']['list'].except!('entry_point') }
      @expected_rdlint_output = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
        filename: filename, section: :protocols, sub_header: :error)
      @option = ''
    end

    it 'displays empty output when all warnings are suppressed on a warnings only result' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
      end
      @expected_rdlint_output = "In file '#{filename}':\n"
      @option = '-w'
    end

    it 'reports a version number with the version option' do
      @descriptor = new_drds_descriptor.tap do |document|
        document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
      end
      @expected_rdlint_output = capture(:stdout) { Crichton::Lint.version } << expected_output(:warning,
        'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link', filename: filename,
        section: :protocols, sub_header: :warning)
      @option = '-v'
    end
  end

  context 'when a user does not specify a filename' do
    it 'reports an error with no options' do
      expect(%x(bundle exec rdlint)).to include(no_file_specified)
    end

    it 'reports an error with the --no_warnings option' do
      expect(%x(bundle exec rdlint -w)).to include(no_file_specified)
    end

    it 'reports an error with the --strict option' do
      expect(%x(bundle exec rdlint -s)).to include(no_file_specified)
    end

    it 'reports an error with the --version option' do
      expect(%x(bundle exec rdlint -v)).to include(no_file_specified)
    end
  end

  context 'when loading an invalid file' do
    it 'reports a load error' do
      @expected_rdlint_output = build_colorized_lint_output(:error, 'catastrophic.cant_load_file',
        exception_message: 'Filename /xxx/yyy is not valid.') << "\n"
      expect(%x(bundle exec rdlint /xxx/yyy)).to eq(@expected_rdlint_output)
    end
  end

  context 'with the --strict option' do
    it 'reports false when errors occur' do
      @descriptor = new_drds_descriptor.tap { |doc| doc['protocols']['http'].except!('list') }
      expect(%x(bundle exec rdlint -s #{filename})).to eq(%Q(#{false_string.red}\n))
    end

    context 'with multiple files' do
      after do
        expect(%x(bundle exec rdlint -s #{@filename1} #{@filename2})).to eq(%Q(#{@output}\n))
      end

      it 'reports false when one clean is clean, one dirty' do
        descriptor = new_drds_descriptor.tap { |doc| doc['protocols']['http'].except!('list') }
        @filename1 = create_drds_file(descriptor, 'missingactions.yml')
        descriptor = new_drds_descriptor.tap { |doc| doc['semantics']['items'].merge!({ 'sample2' => 'GET' }) }
        @filename2 = create_drds_file(descriptor, 'extraprops.yml')
        @output = "false\n".red
      end

      it 'reports true all are clean' do
        descriptor = new_drds_descriptor.tap { |doc| doc['semantics']['items'].merge!({ 'sample2' => 'GET' }) }
        @filename1 = create_drds_file(descriptor, 'extraproperties1.yml')
        @filename2 = create_drds_file(descriptor, 'extraproperties2.yml')
        @output = "true\n".green
      end
    end
  end

  context 'with the --all option' do
    # stub does not work in a new shell apparently, so a forced copy to the default api_descriptor dir is made
    before(:all) do
      FileUtils.rm_rf(Dir.glob("#{SPECS_TEMP_DIR}/crichton.yml"))
      create_drds_file(normalized_drds_descriptor.tap { |doc| doc.except!('protocols') }, 'noprotocols.yml')
      create_drds_file(normalized_drds_descriptor.tap { |doc| doc.except!('descriptors') }, 'nodescriptors.yml')
      build_dir_for_lint_rspec('api_descriptors', "../#{SPECS_TEMP_DIR}")
    end

    it 'processes all the files in the config folder' do
      execution_output = %x(bundle exec rdlint -a)
      all_files_processed = %w(noprotocols.yml nodescriptors.yml).all? { |f| execution_output.include?(f) }
      expect(all_files_processed).to be_true
    end

    it 'returns the correct value together with the --strict option ' do
      expect(%x(bundle exec rdlint -as)).to eq('false'.red << "\n")
    end
  end
end
