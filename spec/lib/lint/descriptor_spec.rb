require 'spec_helper'
require 'lint'

describe Lint do
  before do
    load_lint_translation_file
  end

  it "displays a missing doc property error if a resource doc property is not specified" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_doc_property.yml')

    error =  expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'doc',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a doc property error if a resource doc property is not a valid media type" do
    filename = lint_spec_filename('descriptor_section_errors', 'invalid_doc_property.yml')

    error =  expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html5',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a doc property error if a resource doc property value is not specified" do
    filename = lint_spec_filename('descriptor_section_errors', 'empty_doc_property.yml')

    error =  expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a type property error if a resource type property is missing" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_type_property.yml')

    error =  expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'type',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a type property error if a resource type property is not valid" do
    filename = lint_spec_filename('descriptor_section_errors', 'invalid_type_property.yml')

    error =  expected_output(:error, 'descriptors.type_invalid', resource: 'drds', type_prop: 'idemportant',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a link property warning if a resource link property is missing" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_link_property.yml')

    warning =  expected_output(:warning, 'descriptors.property_missing', resource: 'drds', prop: 'link',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warning
  end

  it "displays an invalid link self property error if a link self property is invalid" do
    filename = lint_spec_filename('descriptor_section_errors', 'invalid_self_link_property.yml')

    error =  expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'selff',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays an invalid link self property error if a link self property value is empty" do
    filename = lint_spec_filename('descriptor_section_errors', 'empty_self_link_property.yml')

    error =  expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'self',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays errors when the descriptor resource names do not match state resource names" do
    filename = lint_spec_filename('descriptor_section_errors', 'mismatched_subresources.yml')

    errors = expected_output(:error, 'descriptors.descriptor_resource_not_found', resource: 'dords',
      filename: filename) <<
      expected_output(:error, 'descriptors.state_resource_not_found', resource: 'drds', filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays an invalid return type error when the descriptor return type is not valid" do
    filename = lint_spec_filename('descriptor_section_errors', 'invalid_return_type.yml')

    error =  expected_output(:error, 'descriptors.invalid_return_type', resource: 'create', rt: 'dord',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a missing return type error when the descriptor return type is missing" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_return_type.yml')

    error =  expected_output(:error, 'descriptors.property_missing', resource: 'create', prop: 'rt',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end


  it "displays errors when the descriptor transitions list does not match state and protocol transitions" do
    filename = lint_spec_filename('descriptor_section_errors', 'missing_transitions.yml')

    errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
      filename: filename) <<
      expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search', filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays errors when the descriptor transition type is associated with an invalid protocol method" do
    filename = lint_spec_filename('descriptor_section_errors', 'invalid_method.yml')

    errors = expected_output(:error, 'descriptors.invalid_method', resource: 'list', type: 'safe', mthd: 'POST',
      filename: filename) <<
      expected_output(:error, 'descriptors.invalid_method', resource: 'create', type: 'unsafe', mthd: 'PUT',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end
end


