require 'spec_helper'
require 'crichton/lint'

module Crichton
  module Lint
    describe ProtocolValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) { lint_spec_filename(*@filename) }

      describe "#validate" do
        context 'when it encounters a protocol without properties' do
          it 'reports a no protocol defined error' do
            filename = lint_spec_filename('protocol_section_errors', 'no_protocol_defined.yml')
            errors = expected_output(:error, 'protocols.protocol_empty', protocol: 'http')
            capture(:stdout) { validator.validate(filename) }.should include(errors)
          end
        end

        context 'when it encounters various error conditions' do
          after do
            validation_report.should == (@errors || @warnings || @message)
          end

          def validation_report
            capture(:stdout) { validator.validate(filename) }
          end

          it 'reports an error when multiple entry points are specified' do
            @filename = %w(protocol_section_errors multiple_entry_points.yml)
            @errors = expected_output(:error, 'protocols.entry_point_error', error: 'Multiple', protocol: 'http',
              filename: filename)
          end

          it 'reports an error when no entry points are specified' do
            @filename = %w(protocol_section_errors no_entry_points.yml)
            @errors = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
              filename: filename)
          end

          it 'reports a warning when an external resource action has properties other than uri_source' do
            @filename = %w(protocol_section_errors extraneous_properties.yml)
            @warnings = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link',
              filename: filename)
          end

          it 'reports errors when uri and method are not specified for a protocol action' do
            @filename = %w(protocol_section_errors missing_required_properties.yml)
            @errors = expected_output(:error, 'protocols.property_missing', property: 'uri', protocol: 'http',
              action: 'list', filename: filename) <<
              expected_output(:error, 'protocols.property_missing', property: 'method', protocol: 'http', action: 'list')
          end

          it 'reports warnings when status codes are not specified properly or are missing' do
            @filename = %w(protocol_section_errors bad_status_codes.yml)
            @warnings = expected_output(:warning, 'protocols.invalid_status_code', code: '99', protocol: 'http',
              action: 'list', filename: filename) <<
              expected_output(:warning, 'protocols.missing_status_codes_property', property: 'notes', protocol: 'http',
              action: 'create') <<
              expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http',
              action: 'search')
          end

          it 'reports errors when content type is not specified properly or are missing' do
            @filename = %w(protocol_section_errors bad_content_type.yml)
            @errors = expected_output(:error, 'protocols.invalid_content_type', content_type: 'application/jason',
              protocol: 'http', action: 'list', filename: filename) <<
              expected_output(:error, 'protocols.property_missing', property: 'content_type', protocol: 'http',
              action: 'create')
          end

          it 'reports warnings when slt properties are not specified properly or are missing' do
            @filename = %w(protocol_section_errors bad_slt_properties.yml)
            @warnings = expected_output(:warning, 'protocols.missing_slt_property', property: 'std_dev', protocol: 'http',
              action: 'list', filename: filename) <<
              expected_output(:warning, 'protocols.property_missing', property: 'slt', protocol: 'http',
              action: 'create')
          end

          it 'reports errors when the protocol actions list does not match state and descriptor transitions' do
            @filename = %w(protocol_section_errors missing_protocol_actions.yml)
            @errors = expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'search',
              protocol: 'http', filename: filename) <<
              expected_output(:error, 'protocols.state_transition_not_found', transition: 'search', protocol: 'http')
          end
        end

        context 'when it encounters an invalid protocol' do
          it 'reports an exception error ' do
            filename = lint_spec_filename('protocol_section_errors', 'invalid_protocol.yml')
            expect { capture(:stdout) { Crichton.Lint.validate(filename) } }.to raise_error
            "Unknown protocol ftp defined in resource descriptor document DRDs."
          end
        end
      end
    end
  end
end
