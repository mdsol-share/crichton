require 'spec_helper'
require 'crichton/lint'

module Crichton
  module Lint
    describe ProtocolValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) { create_drds_file(@descriptor, @filename) }

      before(:all) do
        @filename = 'drds_lint'
      end

      before do
        Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
      end

      describe '#validate' do
        context 'when it encounters a protocol without properties' do
          it 'reports a no protocol defined error' do
            descriptor = new_drds_descriptor.tap { |document| document['protocols']['http'].replace({}) }
            filename = create_drds_file(descriptor, 'drds_lint')
            errors = expected_output(:error, 'protocols.protocol_empty', protocol: 'http')
            expect(capture(:stdout) { validator.validate(filename) }).to include(errors)
          end
        end

        context 'when it encounters various error conditions' do
          after do
            expect(validation_report).to eq(@errors || @warnings || @message)
          end

          def validation_report
            capture(:stdout) { validator.validate(filename) }
          end

          it 'reports an error when multiple entry points are specified' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['create'].merge!({ 'entry_point' => 'drds' })
            end
            @errors = expected_output(:error, 'protocols.entry_point_error', error: 'Multiple', protocol: 'http',
              filename: filename, section: :protocols, sub_header: :error)
          end

          it 'reports an error when no entry points are specified' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['list'].except!('entry_point')
            end
            @errors = expected_output(:error, 'protocols.entry_point_error', error: 'No', protocol: 'http',
              filename: filename, section: :protocols, sub_header: :error)
          end

          it 'reports a warning when an external resource action has properties other than uri_source' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['leviathan-link'].merge!({ 'method' => 'GET' })
            end
            @warnings = expected_output(:warning, 'protocols.extraneous_props', protocol: 'http',
              action: 'leviathan-link', filename: filename, section: :protocols, sub_header: :warning)
          end

          it 'reports errors when uri and method are not specified for a protocol action' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['list'].except!('uri').except!('method')
            end
            @errors = expected_output(:error, 'protocols.property_missing', property: 'uri', protocol: 'http',
              action: 'list', filename: filename, section: :protocols, sub_header: :error) <<
              expected_output(:error, 'protocols.property_missing', property: 'method', protocol: 'http',
                action: 'list')
          end

          it 'reports warnings when status codes are not specified properly or are missing' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['list']['status_codes'].merge!({ 99 => { 'description' => 'OK', 'notes' => 'OK' }})
              document['protocols']['http']['search'].except!('status_codes')
            end
            @warnings = expected_output(:warning, 'protocols.invalid_status_code', code: '99', protocol: 'http',
              action: 'list', filename: filename, section: :protocols, sub_header: :warning) <<
              expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http',
                action: 'search')
          end

          it 'reports warning when status codes are not specified properly' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['create']['status_codes'][201].except!('notes')
            end
            @warnings = expected_output(:warning, 'protocols.missing_status_codes_property', property: 'notes', protocol: 'http',
              action: 'create', filename: filename, section: :protocols, sub_header: :warning)
          end

          it 'reports errors when content type is not specified properly or are missing' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['list']['content_types'] << 'application/jason'
              document['protocols']['http']['create'].except!('content_types')
            end
            @errors = expected_output(:error, 'protocols.invalid_content_type', content_type: 'application/jason',
              protocol: 'http', action: 'list', filename: filename, section: :protocols, sub_header: :error) <<
              expected_output(:error, 'protocols.property_missing', property: 'content_type', protocol: 'http',
              action: 'create')
          end

          it 'reports warnings when slt properties are not specified properly' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['show']['slt'].except!('std_dev')
            end
            @warnings = expected_output(:warning, 'protocols.missing_slt_property', property: 'std_dev',
              protocol: 'http', action: 'show', filename: filename, section: :protocols, sub_header: :warning)
          end

          it 'reports warnings when slt properties are missing' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http']['create'].except!('slt')
            end
            @warnings = expected_output(:warning, 'protocols.property_missing', property: 'slt', protocol: 'http',
              protocol: 'http', action: 'create', filename: filename, section: :protocols, sub_header: :warning)
          end


          it 'reports errors when the protocol actions list does not match state and descriptor transitions' do
            @descriptor = new_drds_descriptor.tap do |document|
              document['protocols']['http'].except!('search')
            end
            @errors = expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'search',
              protocol: 'http', filename: filename, section: :protocols, sub_header: :error) <<
              expected_output(:error, 'protocols.state_transition_not_found', transition: 'search', protocol: 'http')
          end
        end

        context 'when it encounters an invalid protocol' do
          it 'reports an exception error ' do
            @descriptor = new_drds_descriptor.tap do |document|
              content = document['protocols']['http']
              document['protocols'].merge!({ 'ftp' => content })
            end
            expect { capture(:stdout) { Crichton.Lint.validate(filename) } }.to raise_error
            "Unknown protocol ftp defined in resource descriptor document DRDs."
          end
        end
      end
    end
  end
end
