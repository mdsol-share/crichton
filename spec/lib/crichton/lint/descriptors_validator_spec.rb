require 'spec_helper'
require 'crichton/lint'
require 'crichton/lint/embed_validator'
require 'crichton/lint/field_type_validator'

describe Crichton::Lint::DescriptorsValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, LINT_FILENAME) }

  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    @descriptor = drds_descriptor
  end

  describe '#validate' do
    after do
      expect(validation_report(filename)).to eq(@errors || @warnings || @message)
    end

    # TODO: Look into refactoring .tap with something non-block and more readable

    it 'reports a missing doc property error if a resource doc property is not specified' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds'].except!('doc')
      end
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'doc',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a doc property error if a resource doc property is not a valid media type' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['doc'] = { 'html5' => 'Invalid key' }
      end
      @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html5',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a doc property error if a resource doc property value is not specified' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['doc'] = { 'html' => nil }
      end
      @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a type property error if a resource type property is missing' do
      @descriptor = normalized_drds_descriptor.tap do |document|
        document['descriptors']['drds'].except!('type')
      end
      allow(Crichton::Descriptor::Dealiaser).to receive(:dealias).and_return(@descriptor)
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'type',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a type property error if a resource type property is not valid' do
      @descriptor = normalized_drds_descriptor.tap do |document|
        document['descriptors']['drds']['type'] = 'semantics2'
      end
      @errors = expected_output(:error, 'descriptors.type_invalid', resource: 'drds', type_prop: 'semantics2',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a link property warning if a resource link property is missing' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds'].except!('links')
      end
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'link',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid link self property error if a link self property is invalid' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['links'].replace({ 'selff' => 'Invalid self' })
      end
      @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'selff',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid link self property error if a link self property value is empty' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['links'].replace({ 'self' => nil })
      end
      @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'self',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid return type error when the descriptor return type is not valid' do
      @descriptor = drds_descriptor.tap do |document|
        document['unsafe']['create']['rt'] = 'dord'
      end
      @errors = expected_output(:error, 'descriptors.invalid_return_type', resource: 'create', rt: 'dord',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a missing return type error when the descriptor return type is missing' do
      @descriptor = drds_descriptor.tap do |document|
        document['unsafe']['create'].except!('rt')
        document['idempotent']['update'].except!('rt')
      end
      @errors = expected_output(:error, 'descriptors.missing_return_type', resource: 'create', filename: filename,
        section: :descriptors, sub_header: :error)  <<
        expected_output(:error, 'descriptors.missing_return_type', resource: 'update')
    end

    it 'reports errors when the descriptor transitions list does not match state or protocol transitions' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['descriptors'].reject!{ |h| h['href'] == 'search' }
      end
      @errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
        filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search')
    end

    it 'reports errors when the descriptor transition type is associated with an invalid protocol method' do
      @descriptor = drds_descriptor.tap do |document|
        document['http_protocol']['list']['method'] = 'POST'
        document['http_protocol']['create']['method'] = 'PUT'
      end
      @errors = expected_output(:error, 'descriptors.invalid_method', resource: 'list', type: 'safe', mthd: 'POST',
        filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.invalid_method', resource: 'create', type: 'unsafe', mthd: 'PUT')
    end

    it 'reports errors when invalid embedded types are found' do
      @descriptor = drds_descriptor.tap do |document|
        document['semantics']['total_count'].merge!({ 'embed' => 'single-optional-embed' })
        document['semantics']['items'].merge!({ 'embed' => 'multple-optional' })
      end
      @errors = expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'total_count',
        embed_attr: 'single-optional-embed', filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'items', embed_attr: 'multple-optional')
    end

    it 'reports no errors with a descriptor file containing valid field_types and validators' do
      @descriptor = drds_descriptor
      @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
    end

    it 'reports no errors with a descriptor file containing field_type: object' do
      @descriptor = normalized_drds_descriptor.tap do |document|
        document['descriptors']['drds']['descriptors']['create']['descriptors']['destroyed'].merge!('field_type' => 'object')
      end
      @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
    end

    it 'reports an error when external url has fragment' do
      @descriptor = drds_descriptor.tap do |document|
        document['semantics']['total_count']['href'] = 'http://alps.io/schema.org/Integer#fragment'
      end
      @errors = expected_output(:error, 'descriptors.href_not_supported_value', id: 'total_count',
        filename: filename, section: :descriptors, uri: 'http://alps.io/schema.org/Integer#fragment', sub_header: :error)
    end

    context 'select options attributes' do
      it 'reports errors when an option name is not one of the supported names' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['total_count'].merge!({ 'options' => { 'listt' => [ '1', '2' ] } })
          document['semantics']['items'].merge!({ 'options' => { 'hashh' => { 'external' => { 'source' => '' } } } })
        end
        @errors = expected_output(:error, 'descriptors.invalid_options_attribute', id: 'total_count', options_attr:
          'listt', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_options_attribute', id: 'items', options_attr: 'hashh')
      end

      it 'reports errors when several form options have no values' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['total_count'].merge!({ 'options' => { 'id' => nil, 'list' => nil } })
          document['semantics']['items'].merge!({ 'options' => { 'hash' => nil } })
          document['semantics']['uuid'].merge!({ 'options' => { 'external' => nil } })
        end
        @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr:
          'id', filename: filename, section: :descriptors, sub_header: :error)  <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr: 'list') <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'items', options_attr: 'hash') <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'uuid', options_attr: 'external')
      end

      it 'reports errors when multiple options are specified under one descriptor' do
        @descriptor = drds_descriptor.tap do |document|
          options = { 'options' => { 'list' => [ '1' , '2' ], 'hash' => { 'first' => '1' } } }
          document['semantics']['total_count'].merge!(options)
        end
        @errors = expected_output(:error, 'descriptors.multiple_options', id: 'total_count', options_keys:
           'list, hash', filename: filename, section: :descriptors, sub_header: :error)
      end

      it 'reports errors when multiple options enumerators contain the wrong type in its values' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['total_count'].merge!({ 'options' => { 'list' => { }  } })
          document['semantics']['items'].merge!({ 'options' => { 'hash' => [ '1', '2' ] } })
        end
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'total_count', key_type:
            'list', value_type: 'hash', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'items',  key_type:
            'hash', value_type: 'list')
      end

      it 'reports warnings when options enumerators are missing a value' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['items'].merge!({ 'options' => { 'hash' => { 'first' => nil, 'second' => '2' } } })
          options = { 'options' => { 'external' => { 'source' => 'http://example.org', 'prompt' => 'id', 'target' => nil } } }
          document['semantics']['uuid'].merge!(options)
        end
        @warnings = expected_output(:warning, 'descriptors.missing_options_value', id: 'items', options_attr:
            'hash', filename: filename, section: :descriptors, sub_header: :warning) <<
          expected_output(:warning, 'descriptors.missing_options_value', id: 'uuid',  options_attr: 'external')
      end

      it 'reports an error when the value_attribute_name is missing for an external hash or list' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['uuid'].merge!({ 'options' => { 'external' => { 'source' => 'http://example.org' } } })
        end
        @errors = expected_output(:error, 'descriptors.missing_options_key', id: 'uuid',
            options_attr: 'external', child_name: 'target', filename: filename,
            section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.missing_options_key', id: 'uuid',
            options_attr: 'external', child_name: 'prompt')
      end

      it 'reports an error when the source attribute is not a string or has no value' do
        @descriptor = drds_descriptor.tap do |document|
          document['semantics']['total_count'].merge!({'options' => { 'external' => nil} })
          document['semantics']['items'].merge!({ 'options' => { 'external' => { 'source' => { 'first' => 'first' } } } })
        end
        @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'total_count',  options_attr:
            'external', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_source_type', id: 'items',
            options_attr: 'external')
      end

      it 'reports an error when there is no field_type property' do
        @descriptor = drds_descriptor.tap do |document|
          document['safe']['search']['parameters'][0].except!('field_type')
        end
        @errors = expected_output(:error, 'descriptors.missing_field_type', descriptor: 'search_term', parent: 'search',
          filename: filename, section: :descriptors, sub_header: :error)
      end
    end
  end
end
