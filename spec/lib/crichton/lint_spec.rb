require 'spec_helper'
require 'crichton/lint'
require 'colorize'

describe Crichton::Lint do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, @filename) }

  before(:all) do
    @filename = 'drds_lint.yml'
  end

  before do
    Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
    load_lint_translation_file
  end

  describe '.validate' do
    context 'with no options' do
      after do
        expect(validation_report).to eq(@errors || @message)
      end

      def validation_report
        capture(:stdout) { validator.validate(filename) }
      end

      it 'reports a success statement with a clean resource descriptor file' do
        @descriptor = drds_descriptor
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a success statement with a clean already dealiased resource descriptor file' do
        @descriptor = normalized_drds_descriptor
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a missing states section error when the states section is missing' do
        @descriptor = drds_descriptor.tap do |document|
          document['resources']['drds'].except!('states')
          document['resources']['drd'].except!('states')
        end
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
        @descriptor = drds_descriptor.except('protocols')
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'protocols', sub_header: :error)
      end
    end

    context 'with the count: :error or count: :warning option' do
      after do
        expect(Crichton::Lint.validate(filename, @option)).to eq(@count)
      end

      it 'returns no errors for a clean descriptor file' do
        @descriptor = drds_descriptor
        @option = {count: :error}
        @count = 0
      end

      it 'returns no warnings for a clean descriptor file' do
        @descriptor = drds_descriptor
        @option = {count: :warning}
        @count = 0
      end

      it 'returns an expected number of errors for a descriptor file' do
        @descriptor = drds_descriptor.tap do |document|
          document['protocols']['http']['list'].except!('uri').except!('method')
        end
        @option = {count: :error}
        @count = 2
      end

      it 'returns an expected number of errors for a descriptor file with catastrophic errors' do
        @descriptor = drds_descriptor.except('protocols')
        @option = {count: :error}
        @count = 1
      end

      it 'returns an expected number of warnings for a descriptor file' do
        @descriptor = drds_descriptor.tap do |document|
          document['protocols']['http']['list']['status_codes'][200].replace({ 'description' => 'OK' })
          document['protocols']['http']['create']['status_codes'][403].replace({})
        end
        @option = {count: :warning}
        @count = 3
      end
    end

    context 'with the --strict option' do
      after do
        expect(Crichton::Lint.validate(filename, {strict: true})).to (@retval ? be_true : be_false)
      end

      it 'returns true when a clean descriptor file is validated' do
        @descriptor = drds_descriptor
        @retval = true
      end

      it 'returns false when a descriptor file contains errors' do
        @descriptor = drds_descriptor.tap do |document|
          document['protocols']['http'].except!('search')
        end
        @retval = false
      end

      it 'returns false when a catastrophic error is found' do
        @descriptor = drds_descriptor.tap do |document|
          document['resources']['drds'].except!('states')
          document['resources']['drd'].except!('states')
        end
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
        Crichton.stub(:descriptor_location).and_return(SPECS_TEMP_DIR)
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
        Crichton.stub(:descriptor_location).and_return(SPECS_TEMP_DIR)
        create_drds_file(drds_descriptor, 'clean_descriptor_file.yml')
        descriptor = drds_descriptor.tap do |document|
          document['protocols']['http']['list']['status_codes'][200].replace({ 'description' => 'OK' })
          document['protocols']['http']['create']['status_codes'][403].replace({})
        end
        create_drds_file(descriptor, 'warnings_status_codes.yml')
      end

      it 'returns true if the --strict option is set' do
        expect(Crichton::Lint.validate_all({strict: true})).to be_true
      end

      it 'returns an accurate warning count if the --all and count option are set' do
        expect(Crichton::Lint.validate_all({count: :warning})).to eq(3)
      end
    end

    context 'when loading an invalid file' do
      it 'reports a load error' do
        @expected_rdlint_output = build_colorized_lint_output(:error, 'catastrophic.cant_load_file',
          exception_message: 'Filename /xxx/yyy is not valid.') << "\n"
        expect(capture(:stdout) { validator.validate('/xxx/yyy') }).to eq(@expected_rdlint_output)
      end
    end

    context 'when it does not exist' do
      it 'returns an exception if the --all option is set' do
        Crichton.stub(:descriptor_location).and_return('/xxx/yyy')
        expect { validator.validate_all }.to raise_error
        "No resource descriptor directory exists. Default is #{Crichton.descriptor_location}."
      end
    end
  end
end
