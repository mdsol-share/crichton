require 'spec_helper'
require 'crichton/lint'
require 'colorize'

describe Crichton::Lint do
  let(:validator) { Crichton::Lint }
  let(:filename) { lint_spec_filename(*@filename) }

  before do
    load_lint_translation_file
  end

  describe '.validate individual files' do
    context 'with no options' do
      after do
        validation_report.should == (@errors || @message)
      end

      def validation_report
        capture(:stdout) { validator.validate(filename) }
      end

      it 'reports a success statement with a clean resource descriptor file' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        @filename = %w(clean_descriptor_file.yml)
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a missing states section error when the states section is missing' do
        @filename = %w(missing_sections nostate_descriptor.yml)
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'states', sub_header: :error)
      end

      it 'reports a missing descriptor errors when the descriptor section is missing' do
        @filename = %w(missing_sections nodescriptors_descriptor.yml)
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'descriptors', sub_header: :error) <<
          expected_output(:error, 'catastrophic.no_secondary_descriptors')
      end

      it 'reports a missing protocols section error when the protocols section is missing' do
        @filename = %w(missing_sections noprotocols_descriptor.yml)
        @errors = expected_output(:error, 'catastrophic.section_missing', section: :catastrophic, filename: filename,
          missing_section: 'protocols', sub_header: :error)
      end
    end

    context 'with the count: :error or count: :warning option' do
      after do
        Crichton::Lint.validate(filename, @option).should == @count
      end

      it 'returns no errors for a clean descriptor file' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        @filename = %w(clean_descriptor_file.yml)
        @option = {count: :error}
        @count = 0
      end

      it 'returns no warnings for a clean descriptor file' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        @filename = %w(clean_descriptor_file.yml)
        @option = {count: :warning}
        @count = 0
      end

      it 'returns an expected number of errors for a descriptor file' do
        @filename = %w(protocol_section_errors missing_required_properties.yml)
        @option = {count: :error}
        @count = 2
      end

      it 'returns an expected number of errors for a descriptor file with catastrophic errors' do
        @filename = %w(missing_sections noprotocols_descriptor.yml)
        @option = {count: :error}
        @count = 1
      end

      it 'returns an expected number of warnings for a descriptor file' do
        @filename = %w(protocol_section_errors bad_status_codes.yml)
        @option = {count: :warning}
        @count = 3
      end
    end

    context 'with the --strict option' do
      after do
        Crichton::Lint.validate(filename, {strict: true}).should @retval ? be_true : be_false
      end

      it 'returns true when a clean descriptor file is validated' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        @filename = %w(clean_descriptor_file.yml)
        @retval = true
      end

      it 'returns false when a descriptor file contains errors' do
        @filename = %w(protocol_section_errors missing_protocol_actions.yml)
        @retval = false
      end

      it 'returns false when a catastrophic error is found' do
        @filename = %w(missing_sections nostate_descriptor.yml)
        @return_val = false
      end
    end

    context 'when both --strict and other options are set' do
      after do
        Crichton::Lint.validate(filename, @option).should be_false
      end

      # error_count > 0, therefore cannot be false
      it 'the strict option takes precedence over the count: :error option' do
        @filename = %w(missing_sections nodescriptors_descriptor.yml)
        @option = {strict: true, count: :error}
        @retval = false
      end

      it 'the strict option takes precedence over the no_warnings option' do
        @filename = %w(missing_sections nodescriptors_descriptor.yml)
        @option = {strict: true, count: :warning}
        @retval = false
      end
    end
  end

  describe ".validate the config folder" do
    context 'containing files with errors' do
      before(:all) do
        build_dir_for_lint_rspec('api_descriptors', 'fixtures/lint_resource_descriptors/missing_sections')
      end

      after(:all) do
        FileUtils.rm_rf('api_descriptors')
      end

      it 'returns false when both --strict and --all options are set' do
        Crichton::Lint.validate_all({strict: true, all: true}).should be_false
      end
    end

    context 'containing files with no errors' do
      before(:all) do
        build_dir_for_lint_rspec('api_descriptors', 'fixtures/resource_descriptors')
        FileUtils.rm_rf('api_descriptors/leviathans_descriptor_v1.yaml')
      end

      after(:all) do
        FileUtils.rm_rf('api_descriptors')
      end

      it 'returns true if the --strict option is set' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        Crichton::Lint.validate_all({strict: true}).should be_true
      end

      it 'returns an accurate warning count if the --all and count option are set' do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
        Crichton::Lint.validate_all({count: :warning}).should == 15
      end
    end

    context 'when loading an invalid file' do
      it 'reports a load error' do
        @expected_rdlint_output = build_colorized_lint_output(:error, 'catastrophic.cant_load_file',
          exception_message: 'No such file or directory - /xxx/yyy') << "\n"
        capture(:stdout) { validator.validate('/xxx/yyy') }.should == @expected_rdlint_output
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
