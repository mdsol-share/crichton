require 'spec_helper'
require 'lint'

module Lint
  describe StatesValidator do
    let(:validator) { Lint }
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
          transition: 'list', filename: filename) <<
          expected_output(:warning, 'states.doc_property_missing', resource: 'drd', state: 'activated')
      end


      it 'reports errors when next transitions are missing or empty' do
        @filename = %w(state_section_errors missing_and_empty_transitions.yml)
        @errors = expected_output(:error, 'states.empty_missing_next', resource: 'drds', state: 'collection',
          transition: 'list', filename: filename) <<
          expected_output(:error, 'states.empty_missing_next', resource: 'drd', state: 'activated', transition: 'show')
      end

      it 'reports errors when next transitions are pointing to non-existent states' do
        @filename = %w(state_section_errors phantom_transitions.yml)
        @errors = expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drds',
          state: 'navigation', transition: 'self', next_state: 'navegation', filename: filename) <<
          expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drd',
          state: 'activated', transition: 'self', next_state: 'activate')
      end

      it 'reports errors when states transitions does not match protocol or descriptor transitions' do
        @filename = %w(state_section_errors missing_transitions.yml)
        @errors = expected_output(:error, 'states.descriptor_transition_not_found', transition: 'create',
          filename: filename) <<
          expected_output(:error, 'states.protocol_transition_not_found', transition: 'create')
      end
    end
  end
end
