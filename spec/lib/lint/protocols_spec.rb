require 'spec_helper'
require 'lint'

describe Lint do
  before do
    load_lint_translation_file
  end

  it "displays no protocol defined error if there are no protocol properties" do
    filename = lint_spec_filename('protocol_section_errors', 'no_protocol_defined.yml')

    error =  expected_output(:error, 'protocols.protocol_empty', protocol: 'http')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should include(error)
  end

  it "displays error when multiple entry points are specified" do
    filename = lint_spec_filename('protocol_section_errors', 'multiple_entry_points.yml')

    error = expected_output(:error, 'protocols.entry_point_error', error: 'Multiple', protocol: 'http',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays error when no entry points are specified" do
    filename = lint_spec_filename('protocol_section_errors', 'no_entry_points.yml')

    error = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == error
  end

  it "displays a warning when an external resource action has properties other than uri_source" do
    filename = lint_spec_filename('protocol_section_errors', 'extraneous_properties.yml')

    warning = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warning
  end

  it "displays errors when uri and method are not specified for a protocol action" do
    filename = lint_spec_filename('protocol_section_errors', 'missing_required_properties.yml')

    errors = expected_output(:error, 'protocols.property_missing', property: 'uri', protocol: 'http', action: 'list',
      filename: filename) <<
      expected_output(:error, 'protocols.property_missing', property: 'method', protocol: 'http', action: 'list')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays warnings when status codes are not specified properly or are missing" do
    filename = lint_spec_filename('protocol_section_errors', 'bad_status_codes.yml')

    warnings = expected_output(:warning, 'protocols.invalid_status_code', code: '99', protocol: 'http', action: 'list',
      filename: filename) <<
      expected_output(:warning, 'protocols.missing_status_codes_property', property: 'notes', protocol: 'http',
      action: 'create') <<
      expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http',
      action: 'search')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warnings
  end

  it "displays errors when content type is not specified properly or are missing" do
    filename = lint_spec_filename('protocol_section_errors', 'bad_content_type.yml')

    errors = expected_output(:error, 'protocols.invalid_content_type', content_type: 'application/jason',
      protocol: 'http', action: 'list', filename: filename) <<
      expected_output(:error, 'protocols.property_missing', property: 'content_type', protocol: 'http',
      action: 'create')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays warnings when slt properties are not specified properly or are missing" do
    filename = lint_spec_filename('protocol_section_errors', 'bad_slt_properties.yml')

    warnings = expected_output(:warning, 'protocols.missing_slt_property', property: 'std_dev', protocol: 'http',
      action: 'list', filename: filename) <<
      expected_output(:warning, 'protocols.property_missing', property: 'slt', protocol: 'http',
      action: 'create')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warnings
  end

  it "displays errors when the protocol actions list does not match state and descriptor transitions" do
    filename = lint_spec_filename('protocol_section_errors', 'missing_protocol_actions.yml')

    errors = expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'search',
      protocol: 'http', filename: filename) <<
      expected_output(:error, 'protocols.state_transition_not_found', transition: 'search', protocol: 'http')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "displays an exception error when an invalid protocol is specified" do
    filename = lint_spec_filename('protocol_section_errors', 'invalid_protocol.yml')
    expect {capture(:stdout) { Lint.validate(filename) }}.to raise_error "Unknown protocol ftp defined in resource descriptor document DRDs."
  end

end
