require 'spec_helper'
require 'lint'

module Lint
  describe DescriptorsValidator do
    let(:validator) { Lint }
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
          filename: filename)
      end

      it 'reports a doc property error if a resource doc property is not a valid media type' do
        @filename = %w(descriptor_section_errors invalid_doc_property.yml)
        @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html5',
          filename: filename)
     end

      it 'reports a doc property error if a resource doc property value is not specified' do
        @filename = %w(descriptor_section_errors empty_doc_property.yml)
        @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html',
          filename: filename)
      end

      it 'reports a type property error if a resource type property is missing' do
        @filename = %w(descriptor_section_errors missing_type_property.yml)
        @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'type',
          filename: filename)
      end

      it 'reports a type property error if a resource type property is not valid' do
        @filename = %w(descriptor_section_errors invalid_type_property.yml)
        @errors = expected_output(:error, 'descriptors.type_invalid', resource: 'drds', type_prop: 'idemportant',
          filename: filename)
      end

      it 'reports a link property warning if a resource link property is missing' do
        @filename = %w(descriptor_section_errors missing_link_property.yml)
        @warnings = expected_output(:warning, 'descriptors.property_missing', resource: 'drds', prop: 'link',
          filename: filename)
      end

      it 'reports an invalid link self property error if a link self property is invalid' do
        @filename = %w(descriptor_section_errors invalid_self_link_property.yml)
        @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'selff',
          filename: filename)
     end

      it 'reports an invalid link self property error if a link self property value is empty' do
        @filename = %w(descriptor_section_errors empty_self_link_property.yml)
        @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'self',
          filename: filename)
      end

      it 'reports errors when the descriptor resource names do not match state resource names' do
        @filename = %w(descriptor_section_errors mismatched_subresources.yml)
        @errors = expected_output(:error, 'descriptors.descriptor_resource_not_found', resource: 'dords',
          filename: filename) <<
          expected_output(:error, 'descriptors.state_resource_not_found', resource: 'drds')
      end

      it 'reports an invalid return type error when the descriptor return type is not valid' do
        @filename = %w(descriptor_section_errors invalid_return_type.yml)        
        @errors = expected_output(:error, 'descriptors.invalid_return_type', resource: 'create', rt: 'dord',
          filename: filename)
      end

      it 'reports a missing return type error when the descriptor return type is missing' do
        @filename = %w(descriptor_section_errors missing_return_type.yml)
        @errors = expected_output(:error, 'descriptors.property_missing', resource: 'create', prop: 'rt',
          filename: filename)
      end

      it 'reports errors when the descriptor transitions list does not match state or protocol transitions' do
        @filename = %w(descriptor_section_errors missing_transitions.yml)
        @errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
          filename: filename) <<
          expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search')
      end

      it 'reports errors when the descriptor transition type is associated with an invalid protocol method' do
        @filename = %w(descriptor_section_errors invalid_method.yml)
        @errors = expected_output(:error, 'descriptors.invalid_method', resource: 'list', type: 'safe', mthd: 'POST',
          filename: filename) <<
          expected_output(:error, 'descriptors.invalid_method', resource: 'create', type: 'unsafe', mthd: 'PUT')
      end

      it 'reports errors when the descriptor ids are not unique' do
        @filename = %w(descriptor_section_errors non_unique_ids.yml)
        @errors = expected_output(:error, 'descriptors.non_unique_descriptor', element: 'create',
          filename: filename) <<
          expected_output(:error, 'descriptors.non_unique_descriptor', element: 'search')
      end
    end
  end
end

