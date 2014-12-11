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

    it 'reports a missing doc property error if a resource doc property is not specified' do
      @descriptor['resources']['drds'].except!('doc')
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'doc',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a doc property error if a resource doc property is not a valid media type' do
      @descriptor['resources']['drds']['doc'] = { 'html5' => 'Invalid key' }
      @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html5',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a doc property error if a resource doc property value is not specified' do
      @descriptor['resources']['drds']['doc'] = { 'html' => nil }
      @errors = expected_output(:error, 'descriptors.doc_media_type_invalid', resource: 'drds', media_type: 'html',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a type property error if a resource type property is missing' do
      @descriptor = normalized_drds_descriptor
      @descriptor['descriptors']['drds'].except!('type')
      allow(Crichton::Descriptor::Dealiaser).to receive(:dealias).and_return(@descriptor)
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'type',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a type property error if a resource type property is not valid' do
      @descriptor = normalized_drds_descriptor
      @descriptor['descriptors']['drds']['type'] = 'semantics2'
      @errors = expected_output(:error, 'descriptors.type_invalid', resource: 'drds', type_prop: 'semantics2',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a link property warning if a resource link property is missing' do
      @descriptor['resources']['drds'].except!('links')
      @errors = expected_output(:error, 'descriptors.property_missing', resource: 'drds', prop: 'link',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid link self property error if a link self property is invalid' do
      @descriptor['resources']['drds']['links'].replace({ 'selff' => 'Invalid self' })
      @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'selff',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid link self property error if a link self property value is empty' do
      @descriptor['resources']['drds']['links'].replace({ 'self' => nil })
      @errors = expected_output(:error, 'descriptors.link_invalid', resource: 'drds', link: 'self',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports an invalid return type error when the descriptor return type is not valid' do
      @descriptor['unsafe']['create']['rt'] = 'dord'
      @errors = expected_output(:error, 'descriptors.invalid_return_type', resource: 'create', rt: 'dord',
        filename: filename, section: :descriptors, sub_header: :error)
    end

    it 'reports a missing return type error when the descriptor return type is missing' do
      @descriptor['unsafe']['create'].except!('rt')
      @descriptor['idempotent']['update'].except!('rt')
      @errors = expected_output(:error, 'descriptors.missing_return_type', resource: 'create', filename: filename,
        section: :descriptors, sub_header: :error)  <<
        expected_output(:error, 'descriptors.missing_return_type', resource: 'update')
    end

    it 'reports errors when the descriptor transitions list does not match state or protocol transitions' do
      @descriptor['resources']['drds']['descriptors'].reject!{ |h| h['href'] == 'search' }
      @errors = expected_output(:error, 'descriptors.state_transition_not_found', transition: 'search',
        filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.protocol_transition_not_found', transition: 'search')
    end

    it 'reports errors when the descriptor transition type is associated with an invalid protocol method' do
      @descriptor['http_protocol']['list']['method'] = 'POST'
      @descriptor['http_protocol']['create']['method'] = 'PUT'
      @errors = expected_output(:error, 'descriptors.invalid_method', resource: 'list', type: 'safe', mthd: 'POST',
        filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.invalid_method', resource: 'create', type: 'unsafe', mthd: 'PUT')
    end

    it 'reports errors when invalid embedded types are found' do
      @descriptor['semantics']['total_count'].merge!({ 'embed' => 'single-optional-embed' })
      @descriptor['semantics']['items'].merge!({ 'embed' => 'multple-optional' })
      @errors = expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'total_count',
        embed_attr: 'single-optional-embed', filename: filename, section: :descriptors, sub_header: :error) <<
        expected_output(:error, 'descriptors.invalid_embed_attribute', id: 'items', embed_attr: 'multple-optional')
    end

    it 'reports no errors with a descriptor file containing valid field_types and validators' do
      @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
    end

    it 'reports no errors with a descriptor file containing field_type: object' do
      @descriptor = normalized_drds_descriptor
      @descriptor['descriptors']['drds']['descriptors']['create']['descriptors']['destroyed'].merge!('field_type' => 'object')
      @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
    end

    it 'reports an error when external url has fragment' do
      @descriptor['semantics']['total_count']['href'] = 'http://alps.io/schema.org/Integer#fragment'
      @errors = expected_output(:error, 'descriptors.href_not_supported_value', id: 'total_count',
        filename: filename, section: :descriptors, uri: 'http://alps.io/schema.org/Integer#fragment', sub_header: :error)
    end

    context 'select options attributes' do
      it 'reports errors when an option name is not one of the supported names' do
        @descriptor['semantics']['total_count'].merge!({ 'options' => { 'listt' => [ '1', '2' ] } })
        @descriptor['semantics']['items'].merge!({ 'options' => { 'hashh' => { 'external' => { 'source' => '' } } } })
        @errors = expected_output(:error, 'descriptors.invalid_options_attribute', id: 'total_count', options_attr:
          'listt', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_options_attribute', id: 'items', options_attr: 'hashh')
      end

      it 'reports errors when several form options have no values' do
        @descriptor['semantics']['total_count'].merge!({ 'options' => { 'id' => nil, 'list' => nil } })
        @descriptor['semantics']['items'].merge!({ 'options' => { 'hash' => nil } })
        @descriptor['semantics']['uuid'].merge!({ 'options' => { 'external' => nil } })
        @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr:
          'id', filename: filename, section: :descriptors, sub_header: :error)  <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'total_count', options_attr: 'list') <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'total_count', key_type: 'list', value_type: 'NilClass') <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'items', options_attr: 'hash') <<
          expected_output(:error, 'descriptors.missing_options_value', id: 'uuid', options_attr: 'external')
      end

      it 'reports errors when multiple options are specified under one descriptor' do
        options = { 'options' => { 'list' => [ '1' , '2' ], 'hash' => { 'first' => '1' } } }
        @descriptor['semantics']['total_count'].merge!(options)
        @errors = expected_output(:error, 'descriptors.multiple_options', id: 'total_count', options_keys:
           'list, hash', filename: filename, section: :descriptors, sub_header: :error)
      end

      it 'reports errors when multiple options enumerators contain the wrong type in its values' do
        @descriptor['semantics']['total_count'].merge!({ 'options' => { 'list' => { }  } })
        @descriptor['semantics']['items'].merge!({ 'options' => { 'hash' => [ '1', '2' ] } })
        @errors = expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'total_count', key_type:
            'list', value_type: 'Hash', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_enumerator', id: 'items',  key_type:
            'hash', value_type: 'list')
      end

      it 'reports warnings when options enumerators are missing a value' do
          @descriptor['semantics']['items'].merge!({ 'options' => { 'hash' => { 'first' => nil, 'second' => '2' } } })
          options = { 'options' => { 'external' => { 'source' => 'http://example.org', 'prompt' => 'id', 'target' => nil } } }
          @descriptor['semantics']['uuid'].merge!(options)
        @warnings = expected_output(:warning, 'descriptors.missing_options_value', id: 'items', options_attr:
            'hash', filename: filename, section: :descriptors, sub_header: :warning) <<
          expected_output(:warning, 'descriptors.missing_options_value', id: 'uuid',  options_attr: 'external')
      end

      it 'reports an error when the value_attribute_name is missing for an external hash or list' do
          @descriptor['semantics']['uuid'].merge!({ 'options' => { 'external' => { 'source' => 'http://example.org' } } })
        @errors = expected_output(:error, 'descriptors.missing_options_key', id: 'uuid',
            options_attr: 'external', child_name: 'target', filename: filename,
            section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.missing_options_key', id: 'uuid',
            options_attr: 'external', child_name: 'prompt')
      end

      it 'reports an error when the source attribute is not a string or has no value' do
          @descriptor['semantics']['total_count'].merge!({'options' => { 'external' => nil} })
          @descriptor['semantics']['items'].merge!({ 'options' => { 'external' => { 'source' => { 'first' => 'first' } } } })
        @errors = expected_output(:error, 'descriptors.missing_options_value', id: 'total_count',  options_attr:
            'external', filename: filename, section: :descriptors, sub_header: :error) <<
          expected_output(:error, 'descriptors.invalid_option_source_type', id: 'items',
            options_attr: 'external')
      end

      it 'reports an error when there is no field_type property' do
          @descriptor['safe']['search']['parameters'][0].except!('field_type')
        @errors = expected_output(:error, 'descriptors.missing_field_type', descriptor: 'search_term', parent: 'search',
          filename: filename, section: :descriptors, sub_header: :error)
      end
    end
  end
end
