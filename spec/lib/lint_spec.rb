require 'spec_helper'
require 'lint'
require 'colorize'

describe Lint do
  let(:validator) { Lint }
  let(:filename) { lint_spec_filename(*@filename) }

  before do
    load_lint_translation_file
  end

  describe '.validate' do
    context 'without the --strict option' do
      after do
        validation_report.should == (@errors || @message)
      end

      def validation_report
        capture(:stdout) { validator.validate(filename) }
      end

      it 'reports a success statement with a clean resource descriptor file' do
        @filename = %w( clean_descriptor_file.yml)
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a missing states section error when the states section is missing' do
        @filename = %w(missing_sections nostate_descriptor.yml)
        @errors = expected_output(:error, 'catastrophic.section_missing', section: 'states', filename: filename)
      end

      it 'reports a missing descriptor errors when the descriptor section is missing' do
        @filename = %w(missing_sections nodescriptors_descriptor.yml)

        @errors = expected_output(:error, 'catastrophic.section_missing', section: 'descriptors', filename: filename) <<
          expected_output(:error, 'catastrophic.no_secondary_descriptors')
      end

      it 'reports a missing protocols section error when the protocols section is missing' do
        @filename = %w(missing_sections noprotocols_descriptor.yml)
        @errors = expected_output(:error, 'catastrophic.section_missing', section: 'protocols', filename: filename)
      end
    end

    context 'with the --strict option' do
      after do
        Lint.validate(filename, {strict: true}).should @retval ? be_true : be_false
      end

      it 'returns true  when a clean descriptor file is validated' do
        @filename = %w(protocol_section_errors extraneous_properties.yml)
        @retval = true
      end

      it 'returns false when a descriptor file contains errors' do
        @filename = %w(protocol_section_errors missing_protocol_actions.yml)
        @retval = false
      end

      it 'returns false  when a catastrophic error is found' do
        @filename = %w(missing_sections nostate_descriptor.yml)
        @return_val = false
      end
    end
  end
end
