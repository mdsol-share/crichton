require 'spec_helper'
require 'crichton/lint'
require 'colorize'

describe Crichton::Lint do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, LINT_FILENAME) }
  
  it 'prints the Crichton version' do
    expect(capture(:stdout) { Crichton::Lint.version }).to eq("Crichton version: 0.1.0\n\n")
  end

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    load_lint_translation_file
    @descriptor = drds_descriptor
  end

  describe '.validate' do
      
    context 'with parsed hash file' do
      let(:loaded_file) { YAML.load_file(create_drds_file(@descriptor, LINT_FILENAME)) }
      
      it 'reports a success statement with a clean file' do
        expect(validation_report(loaded_file)).to eq("In file '#{loaded_file}':\n#{I18n.t('aok').green}\n")
      end
    end
  
    context 'with no options' do
      after do
        expect(validation_report(filename)).to eq(@errors || @warnings || @message)
      end

      it 'reports a success statement with a clean resource descriptor file' do
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a success statement with a clean already dealiased resource descriptor file' do
        @descriptor = normalized_drds_descriptor
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a missing states section error when the states section is missing' do
          @descriptor['resources']['drds'].except!('states')
          @descriptor['resources']['drd'].except!('states')
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'states', sub_header: :error)
      end

      it 'reports a missing descriptor errors when the descriptor section is missing' do
        @descriptor = normalized_drds_descriptor.except('descriptors')
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'descriptors', sub_header: :error) <<
          expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, missing_section: 'states') <<
          expected_output(:error, 'catastrophic.no_secondary_descriptors')
      end

      it 'reports a missing protocols section error when the protocols section is missing' do
        @descriptor.except!('http_protocol')
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'protocols', sub_header: :error)
      end

      it 'reports a missing top-level self property' do
        @descriptor['links'].except!('self')
        @errors = expected_output(:error, 'profile.missing_self', section: :catastrophic, filename: filename, sub_header: :error) <<
            expected_output(:error, 'profile.missing_self_value')
      end
    end

    context 'with the count: :error or count: :warning option' do
      after do
        expect(Crichton::Lint.validate(filename, @option)).to eq(@count)
      end

      it 'returns no errors for a clean descriptor file' do
        @option = {count: :error}
        @count = 0
      end

      it 'returns no warnings for a clean descriptor file' do
        @option = {count: :warning}
        @count = 0
      end

      it 'returns an expected number of errors for a descriptor file' do
          @descriptor['http_protocol']['list'].except!('uri').except!('method')
        @option = {count: :error}
        @count = 2
      end

      it 'returns an expected number of errors for a descriptor file with catastrophic errors' do
        @descriptor.except!('http_protocol')
        @option = {count: :error}
        @count = 1
      end

      it 'returns an expected number of warnings for a descriptor file' do
          @descriptor['http_protocol']['repair-history'].merge!({ 'method' => 'GET' })
          @descriptor['http_protocol']['leviathan-link'].merge!({ 'method' => 'GET' })
        @option = {count: :warning}
        @count = 2
      end
    end

    context 'with the --strict option' do
      after do
        expect(Crichton::Lint.validate(filename, {strict: true})).to (@retval ? be_true : be_false)
      end

      it 'returns true when a clean descriptor file is validated' do
        @retval = true
      end

      it 'returns false when a descriptor file contains errors' do
          @descriptor['http_protocol'].except!('search')
        @retval = false
      end

      it 'returns false when a catastrophic error is found' do
          @descriptor['resources']['drds'].except!('states')
          @descriptor['resources']['drd'].except!('states')
        @return_val = false
      end
    end

    context 'when both --strict and other options are set' do
      after do
        expect(Crichton::Lint.validate(filename, @option)).to be_false
      end

      # error_count > 0, therefore cannot be false
      it 'the strict option takes precedence over the count: :error option' do
        @descriptor = normalized_drds_descriptor.except('descriptors')
        @option = {strict: true, count: :error}
        @retval = false
      end

      it 'the strict option takes precedence over the no_warnings option' do
        @descriptor = normalized_drds_descriptor.except('descriptors')
        @option = {strict: true, count: :warning}
        @retval = false
      end
    end
  end

  context 'with the descriptor file config folder' do
    context 'containing files with errors' do
      before do
        FileUtils.rm_rf(Dir.glob("#{SPECS_TEMP_DIR}/*.yml"))
        allow(Crichton).to receive(:descriptor_location).and_return(SPECS_TEMP_DIR)
        create_drds_file(normalized_drds_descriptor.except('descriptors'), 'nodescriptors_descriptor.yml')
        create_drds_file(normalized_drds_descriptor.except('protocols'), 'noprotocols_descriptor.yml')
      end

      it 'returns false when both --strict and --all options are set' do
        expect(Crichton::Lint.validate_all({strict: true, all: true})).to be_false
      end
    end

    context 'containing files with no errors' do
      before do
        FileUtils.rm_rf(Dir.glob("#{SPECS_TEMP_DIR}/*.yml"))
        allow(Crichton).to receive(:descriptor_location).and_return(SPECS_TEMP_DIR)
        create_drds_file(drds_descriptor, 'clean_descriptor_file.yml')
        @descriptor['http_protocol']['leviathan-link'].merge!({ 'method' => 'GET' })
        create_drds_file(@descriptor, 'warnings_extra_properties.yml')
      end

      it 'returns true if the --strict option is set' do
        expect(Crichton::Lint.validate_all({strict: true})).to be_true
      end

      it 'returns an accurate warning count if the --all and count option are set' do
        expect(Crichton::Lint.validate_all({count: :warning})).to eq(1)
      end
    end

    context 'when loading an invalid file' do
      it 'reports a load error' do
        @expected_rdlint_output = build_colorized_lint_output(:error, 'catastrophic.cant_load_file',
          exception_message: 'Filename /xxx/yyy is not valid.') << "\n"
        expect(capture(:stdout) { validator.validate('/xxx/yyy') }).to include(@expected_rdlint_output)
      end
    end

    context 'when it does not exist' do
      it 'returns an exception if the --all option is set' do
        allow(Crichton).to receive(:descriptor_location).and_return('/xxx/yyy')
        expect { validator.validate_all }.to raise_error
        "No resource descriptor directory exists. Default is #{Crichton.descriptor_location}."
      end
    end
    
    context 'when linting the errors descriptor file' do
      it 'passes even if the --strict option is set' do
        drds_path = crichton_fixture_path('resource_descriptors', 'errors_descriptor.yml')
        expect(Crichton::Lint.validate(drds_path, {strict: true})).to be_true
      end
    end
    
  end
end
