require 'spec_helper'
require 'crichton/lint'

describe Crichton::Lint::ProtocolValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, LINT_FILENAME) }

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    @descriptor = drds_descriptor
  end

  describe '#validate' do
    context 'when it encounters a protocol without properties' do
      it 'reports a no protocol defined error' do
        @descriptor['http_protocol'].replace({})
        errors = expected_output(:error, 'protocols.protocol_empty', protocol: 'http')
        expect(capture(:stdout) { validator.validate(filename) }).to include(errors)
      end
    end

    context 'when it encounters various error conditions' do
      after do
        expect(validation_report(filename)).to eq(@errors || @warnings || @message)
      end

      it 'reports an error when multiple entry points are specified' do
          @descriptor['http_protocol']['create'].merge!({ 'entry_point' => 'drds' })
        @errors = expected_output(:error, 'protocols.entry_point_error', error: 'Multiple', protocol: 'http',
          filename: filename, section: :protocols, sub_header: :error)
      end

      it 'reports an error when no entry points are specified' do
          @descriptor['http_protocol']['list'].except!('entry_point')
        @errors = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
          filename: filename, section: :protocols, sub_header: :error)
      end

      it 'reports a warning when an external resource action has properties other than uri_source' do
          @descriptor['http_protocol']['leviathan-link'].merge!({ 'method' => 'GET' })
        @warnings = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http',
          action: 'leviathan-link', filename: filename, section: :protocols, sub_header: :warning)
      end

      it 'reports errors when uri and method are not specified for a protocol action' do
          @descriptor['http_protocol']['list'].except!('uri').except!('method')
        @errors = expected_output(:error, 'protocols.property_missing', property: 'uri', protocol: 'http',
          action: 'list', filename: filename, section: :protocols, sub_header: :error) <<
          expected_output(:error, 'protocols.property_missing', property: 'method', protocol: 'http',
            action: 'list')
      end

      it 'reports warnings when slt properties are not specified properly' do
          @descriptor['http_protocol']['show']['slt'].except!('std_dev')
        @warnings = expected_output(:warning, 'protocols.missing_slt_property', property: 'std_dev',
          protocol: 'http', action: 'show', filename: filename, section: :protocols, sub_header: :warning)
      end

      it 'reports warnings when slt properties are missing' do
          @descriptor['http_protocol']['create'].except!('slt')
        @warnings = expected_output(:warning, 'protocols.property_missing', property: 'slt', protocol: 'http',
          protocol: 'http', action: 'create', filename: filename, section: :protocols, sub_header: :warning)
      end


      it 'reports errors when the protocol actions list does not match state and descriptor transitions' do
          @descriptor['http_protocol'].except!('search')
        @errors = expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'search',
          protocol: 'http', filename: filename, section: :protocols, sub_header: :error) <<
          expected_output(:error, 'protocols.state_transition_not_found', transition: 'search', protocol: 'http') <<
          expected_output(:error, 'routes.missing_protocol_transitions', section: :routes,
          sub_header: :error, route: 'search', resource: 'DRDs')
      end
    end

    context 'when it encounters an invalid protocol' do
      it 'reports an exception error ' do
          content = @descriptor['http_protocol']
          @descriptor.merge!({ 'ftp_protocol' => content })
        expect { capture(:stdout) { Crichton.Lint.validate(filename) } }.to raise_error
        "Unknown protocol ftp defined in resource descriptor document DRDs."
      end
    end
  end
end
