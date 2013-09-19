require 'spec_helper'
require 'lint'

describe Lint do
  before do
    load_lint_translation_file
  end

  it "displays errors when the descriptor transitions list does not match state and protocol transitions" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_transitions.yml')

    errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
      filename: filename) <<
      expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search', filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

end


