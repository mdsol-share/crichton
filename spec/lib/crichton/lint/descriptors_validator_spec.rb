require 'spec_helper'
require 'crichton/lint'
require 'crichton/lint/embed_validator'
require 'crichton/lint/field_type_validator'

module Crichton
  module Lint
    describe DescriptorsValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) { lint_spec_filename(*@filename) }

      describe '#validate' do
        after do
          validation_report.should == (@errors || @warnings || @message)
        end

        def validation_report
          capture(:stdout) { validator.validate(filename) }
        end

        it 'reports a missing doc property error if a resource doc property is not specified' do
          @filename = %w(descriptor_section_errors missing_doc_property.yml)
          @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'doc',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a doc property error if a resource doc property is not a valid media type' do
          @filename = %w(descriptor_section_errors invalid_doc_property.yml)
          @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html5',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a doc property error if a resource doc property value is not specified' do
          @filename = %w(descriptor_section_errors empty_doc_property.yml)
          @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a type property error if a resource type property is missing' do
          @filename = %w(descriptor_section_errors missing_type_property.yml)
          @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'type',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a type property error if a resource type property is not valid' do
          @filename = %w(descriptor_section_errors invalid_type_property.yml)
          @errors = expected_output(:error, 'descriptors.type_invalid', resource: 'drds', type_prop: 'idemportant',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a link property warning if a resource link property is missing' do
          @filename = %w(descriptor_section_errors missing_link_property.yml)
          @warnings = expected_output(:warning, 'descriptors.property_missing', resource: 'drds', prop: 'link',
            filename: filename, section: :descriptors, sub_header: :warning)
        end

        it 'reports an invalid link self property error if a link self property is invalid' do
          @filename = %w(descriptor_section_errors invalid_self_link_property.yml)
          @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'selff',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports an invalid link self property error if a link self property value is empty' do
          @filename = %w(descriptor_section_errors empty_self_link_property.yml)
          @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'self',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports errors when the descriptor resource names do not match state resource names' do
          @filename = %w(descriptor_section_errors mismatched_subresources.yml)
          @errors = expected_output(:error, 'descriptors.descriptor_resource_not_found', resource: 'dords',
            filename: filename, section: :descriptors, sub_header: :error) <<
            expected_output(:error, 'descriptors.state_resource_not_found', resource: 'drds')
        end

        it 'reports an invalid return type error when the descriptor return type is not valid' do
          @filename = %w(descriptor_section_errors invalid_return_type.yml)
          @errors = expected_output(:error, 'descriptors.invalid_return_type', resource: 'create', rt: 'dord',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports a missing return type error when the descriptor return type is missing' do
          @filename = %w(descriptor_section_errors missing_return_type.yml)
          @errors = expected_output(:error, 'descriptors.missing_return_type', resource: 'create', filename: filename,
            section: :descriptors, sub_header: :error)
        end

        it 'reports errors when the descriptor transitions list does not match state or protocol transitions' do
          @filename = %w(descriptor_section_errors missing_transitions.yml)
          @errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
            filename: filename, section: :descriptors, sub_header: :error) <<
            expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search')
        end

        it 'reports errors when the descriptor transition type is associated with an invalid protocol method' do
          @filename = %w(descriptor_section_errors invalid_method.yml)
          @errors = expected_output(:error, 'descriptors.invalid_method', resource: 'list', type: 'safe', mthd: 'POST',
            filename: filename, section: :descriptors, sub_header: :error) <<
            expected_output(:error, 'descriptors.invalid_method', resource: 'create', type: 'unsafe', mthd: 'PUT')
        end

        it 'reports errors when the descriptor ids are not unique' do
          @filename = %w(descriptor_section_errors non_unique_ids.yml)
          @errors = expected_output(:error, 'descriptors.non_unique_descriptor', id: 'filter', parent: 'form-search',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports errors when field_type names are not valid' do
          @filename = %w(descriptor_section_errors invalid_field_type.yml)
          @errors = expected_output(:error, 'descriptors.invalid_field_type', id: 'create-drd', field_type: 'textt',
            filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports errors when field_type validator names are not valid' do
          @filename = %w(descriptor_section_errors invalid_field_validator.yml)
          @errors = expected_output(:error, 'descriptors.invalid_field_validator', id: 'create-drd', field_type: 'text',
            validator: 'maxlen', filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports errors when a validator is not permitted for a field_type' do
          @filename = %w(descriptor_section_errors disallowed_field_validator.yml)
          @errors = expected_output(:error, 'descriptors.not_permitted_field_validator', id: 'create-drd', field_type:
            'datetime', validator: 'maxlength', filename: filename, section: :descriptors, sub_header: :error)
        end

        it 'reports errors when invalid embedded types are found' do
          @filename = %w(descriptor_section_errors invalid_embed_types.yml)
          @errors = expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'total_count',
            embed_attr: 'single-optional-embed', filename: filename, section: :descriptors, sub_header: :error) <<
            expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'items', embed_attr: 'multple-optional')
        end

        it 'reports no errors with a descriptor file containing valid field_types and validators' do
          Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
          @filename = %w(clean_descriptor_file.yml)
          @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
        end

        context 'select options attributes' do
          it 'reports errors when an option name is not one of the supported names' do
            @filename = %w(descriptor_section_errors bad_option_names.yml)
            @errors = expected_output(:error, 'descriptors.invalid_options_attribute', id: 'total_count', options_attr:
              'listt', filename: filename, section: :descriptors, sub_header: :error) <<
              expected_output(:error, 'descriptors.invalid_options_attribute', id: 'items', options_attr: 'hashh')
          end

          it 'reports errors when several form options have no values' do
            @filename = %w(descriptor_section_errors missing_options_values.yml)
            @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr:
              'id', filename: filename, section: :descriptors, sub_header: :error)  <<
              expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr: 'list') <<
              expected_output(:error, 'descriptors.missing_options_value', id: 'items', options_attr: 'hash') <<
              expected_output(:error, 'descriptors.missing_options_value', id: 'uuid',  options_attr:
                'external_list') <<
              expected_output(:error, 'descriptors.missing_options_value', id: 'name', options_attr:
                'external_hash')
          end

          it 'reports errors when multiple options are specified under one descriptor' do
            @filename = %w(descriptor_section_errors multiple_options.yml)
            @errors = expected_output(:error, 'descriptors.multiple_options', id: 'total_count', options_keys:
               'list, hash', filename: filename, section: :descriptors, sub_header: :error)
          end

          it 'reports errors when multiple options enumerators contain the wrong type in its values' do
            @filename = %w(descriptor_section_errors bad_option_enumerator_types.yml)
            @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'total_count', key_type:
              'list', value_type: 'hash', filename: filename, section: :descriptors, sub_header: :error) <<
              expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'items',  key_type:
              'hash', value_type: 'list')
          end

          it 'reports warnings when options enumerators are missing a value' do
            @filename = %w(descriptor_section_errors missing_option_enumerator_values.yml)
            @warnings = expected_output(:warning, 'descriptors.missing_options_value', id: 'items', options_attr:
              'hash', filename: filename, section: :descriptors, sub_header: :warning) <<
              expected_output(:warning, 'descriptors.missing_options_value', id: 'uuid',  options_attr:
              'text_attribute_name')
          end

          # FINISH WITH 8, 9 10
        end
      end
    end
  end
end
