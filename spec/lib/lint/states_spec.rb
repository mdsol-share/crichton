require 'spec_helper'
require 'lint'

describe Lint do
  before do
    load_lint_translation_file
  end

  it "display warnings correlating to self: and doc: issues when they are found in a descriptor file" do
    filename = lint_spec_filename('state_section_errors', 'condition_doc_and_self_errors.yml')

    warnings = expected_output(:warning, 'states.no_self_property', resource: 'drds',
      state: 'collection', transition: 'list',  filename: filename) <<
      expected_output(:warning, 'states.doc_property_missing', resource: 'drd', state: 'activated',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warnings
  end

  it "display errors when next transitions are missing or empty" do
    filename = lint_spec_filename('state_section_errors', 'missing_and_empty_transitions.yml')

    errors = expected_output(:error, 'states.empty_missing_next', resource: 'drds',
      state: 'collection', transition: 'list',  filename: filename) <<
      expected_output(:error, 'states.empty_missing_next', resource: 'drd',
      state: 'activated', transition: 'show',  filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "display errors when next transitions are pointing to non-existent states" do
    filename = lint_spec_filename('state_section_errors', 'phantom_transitions.yml')

    errors = expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drds',
      state: 'navigation', transition: 'self', next_state: 'navegation',  filename: filename) <<
      expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drd',
      state: 'activated', transition: 'self', next_state: 'activate',  filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays errors when the states transition list does not match protocol and descriptor transitions" do
    filename = lint_spec_filename('state_section_errors', 'missing_transitions.yml')

    errors = expected_output(:error, 'states.descriptor_transition_not_found', transition: 'create',
      filename: filename) <<
      expected_output(:error, 'states.protocol_transition_not_found', transition: 'create',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

end
