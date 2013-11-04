require 'spec_helper'
require 'crichton/lint'

module Crichton
  module Lint
    describe StatesValidator do
      let(:validator) { Crichton::Lint }
      let(:filename) { lint_spec_filename(*@filename) }

      describe '#validate' do
        after do
          validation_report.should == (@errors || @warnings || @message)
        end

        def validation_report
          capture(:stdout) { validator.validate(filename) }
        end

        it 'reports warnings correlating to self: and doc: issues' do
          @filename = %w(state_section_errors condition_doc_and_self_errors.yml)
          @warnings = expected_output(:warning, 'states.no_self_property', resource: 'drds', state: 'collection',
            transition: 'list', filename: filename, section: :states, sub_header: :warning) <<
            expected_output(:warning, 'states.doc_property_missing', resource: 'drd', state: 'activated')
        end

        it 'reports errors when next transitions are missing or empty' do
          @filename = %w(state_section_errors missing_and_empty_transitions.yml)
          @errors = expected_output(:error, 'states.empty_missing_next', resource: 'drds', state: 'collection',
            transition: 'list', filename: filename, section: :states, sub_header: :error) <<
            expected_output(:error, 'states.empty_missing_next', resource: 'drd', state: 'activated',
              transition: 'show')
        end

        it 'reports errors when next transitions are pointing to non-existent states' do
          @filename = %w(state_section_errors phantom_transitions.yml)
          @errors = expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drds',
            state: 'navigation', transition: 'self', next_state: 'navegation', filename: filename, section: :states,
            sub_header: :error) <<
            expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drd',
            state: 'activated', transition: 'self', next_state: 'activate')
        end

        it 'reports errors when states transitions does not match protocol or descriptor transitions' do
          @filename = %w(state_section_errors missing_transitions.yml)
          @errors = expected_output(:error, 'states.descriptor_transition_not_found', transition: 'create',
            filename: filename, section: :states, sub_header: :error) <<
            expected_output(:error, 'states.protocol_transition_not_found', transition: 'create')
        end

        it 'reports a warning when a transition-less state does not contain a location' do
          @filename = %w(state_section_errors missing_location.yml)
          @warnings = expected_output(:warning, 'states.location_property_missing', resource: 'drds', state: 'deleted',
            filename: filename, section: :states, sub_header: :warning)
        end

        it 'reports an error if a resource has no states defined' do
          @filename = %w(state_section_errors no_states_defined.yml)
          @errors = expected_output(:error, 'catastrophic.no_states', resource: 'drd',  filename: filename,
            section: :states, sub_header: :error)
        end

        context 'an external profile' do
          let(:external_url) { 'http://alps.io/schema.org/Leviathans' }

           it 'reports no errors when it is already downloaded to disk' do
            Crichton::ExternalDocumentStore.any_instance.stub(:get).and_return('<alps></alps>')
            @filename = %w(clean_descriptor_file.yml)
            @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
          end

          it 'reports an error if its url points to an invalid address' do
            stub_profile_request(404)
            @filename = %w(state_section_errors external_profile.yml)
            @errors = expected_output(:error, 'states.invalid_external_location', link: external_url,
              secondary_descriptor: 'drd', state: 'activated', transition: 'self', filename: filename, section: :states,
              sub_header: :error)
          end

          it 'reports a warning if its url has a valid address but is not downloaded to disk' do
            stub_profile_request(200)
            @filename = %w(state_section_errors external_profile.yml)
            @warnings = expected_output(:warning, 'states.download_external_profile', link: external_url,
              secondary_descriptor: 'drd', state: 'activated', transition: 'self', filename: filename, section: :states,
              sub_header: :warning)
          end

          def stub_profile_request(status)
            stub_request(:get, external_url).with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
              to_return(:status => status, :body => "", :headers => {})
            StateTransitionDecorator.any_instance.stub(:next_state_location).and_return(external_url)
          end
        end
      end
    end
  end
end
