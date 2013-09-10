require 'spec_helper'
require 'lint'

describe Lint do
  before do
    load_lint_translation_file
  end

  describe '.validate' do
    it "displays a success statement when linting a clean resource descriptor file" do
      filename = lint_spec_filename('', 'clean_descriptor_file.yml')
      content = capture(:stdout) { Lint.validate(filename) }
      content.should == "#{I18n.t('aok')}\n"
    end

    it "display a missing states section error when the states section is missing" do
      filename = lint_spec_filename('missing_sections', 'nostate_descriptor.yml')
      content = capture(:stdout) { Lint.validate(filename) }
      error = expected_output(:error, 'catastrophic.section_missing', section: 'states', filename: filename)
      content.should == error
    end

    it "display missing descriptor errors when the descriptor section is missing" do
      filename = lint_spec_filename('missing_sections', 'nodescriptors_descriptor.yml')

      errors = expected_output(:error, 'catastrophic.section_missing',
                               section: 'descriptors', filename: filename) <<
        expected_output(:error, 'catastrophic.no_secondary_descriptors')

      content = capture(:stdout) { Lint.validate(filename) }
      content.should == errors
    end

    it "display a missing protocols section error when the protocols section is missing" do
      filename = lint_spec_filename('missing_sections', 'noprotocols_descriptor.yml')
      content = capture(:stdout) { Lint.validate(filename) }
      error = expected_output(:error, 'catastrophic.section_missing', section: 'protocols', filename: filename)
      content.should == error
    end
  end
end
