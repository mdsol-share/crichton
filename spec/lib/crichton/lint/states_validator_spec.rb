require 'spec_helper'
require 'crichton/lint'

describe Crichton::Lint::StatesValidator do
  let(:validator) { Crichton::Lint }
  let(:filename) { create_drds_file(@descriptor, @dest_filename) }

  before(:all) do
    @dest_filename = 'drds_lint.yml'
  end

  describe '#validate' do
    before do
      allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).with(an_instance_of(Addressable::URI)).and_return('<alps></alps>')
      allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).with(/alps/).and_return('<alps></alps>')
      allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).with('http://schema.org/Something').and_return(nil)
      @descriptor = drds_descriptor
    end

    after do
      expect(validation_report(filename)).to eq(@errors || @warnings || @message)
    end

    it 'reports warnings correlating to self: and doc: issues' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions']['list'].merge!({ 'name' => 'selff' })
        document['resources']['drds']['states']['collection']['transitions']['create'].merge!({ 'name' => 'self' })
        document['resources']['drd']['states']['activated'].except!('doc')
      end
      @warnings = expected_output(:warning, 'states.no_self_property', resource: 'drds', state: 'collection',
        transition: 'list', filename: filename, section: :states, sub_header: :warning) <<
        expected_output(:warning, 'states.doc_property_missing', resource: 'drd', state: 'activated')
    end

    it 'reports errors when next transitions are missing or empty' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions']['list'].except!('next')
        document['resources']['drd']['states']['activated']['transitions']['show'].except!('next')
      end
      @errors = expected_output(:error, 'states.empty_missing_next', resource: 'drds', state: 'collection',
        transition: 'list', filename: filename, section: :states, sub_header: :error) <<
        expected_output(:error, 'states.empty_missing_next', resource: 'drd', state: 'activated',
          transition: 'show')
    end

    it 'reports errors when next transitions are pointing to non-existent states' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['navigation']['transitions']['search']['next'] = ['navegation']
        document['resources']['drd']['states']['activated']['transitions']['show']['next'] = ['activate']
      end
      @errors = expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drds',
        state: 'navigation', transition: 'self', next_state: 'navegation', filename: filename, section: :states,
        sub_header: :error) <<
        expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drd',
        state: 'activated', transition: 'self', next_state: 'activate')
    end

    it 'reports errors when states transitions does not match protocol or descriptor transitions' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions'].except!('create')
        document['resources']['drds']['states']['navigation']['transitions'].except!('create')
      end
      @errors = expected_output(:error, 'states.descriptor_transition_not_found', transition: 'create',
        filename: filename, section: :states, sub_header: :error) <<
        expected_output(:error, 'states.protocol_transition_not_found', transition: 'create')
    end

    it 'reports a warning when a transition-less state does not contain a location' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drd']['states']['deleted'].except!('location')
      end
      @warnings = expected_output(:warning, 'states.location_property_missing', resource: 'drd', state: 'deleted',
        filename: filename, section: :states, sub_header: :warning)
    end

    it 'reports an error if no state transitions define "name:self" property' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions']['list'].except!('name')
      end
      @errors = expected_output(:error, 'states.name_self_exception', filename: filename,
        section: :states, sub_header: :error, state: 'collection')
    end

    it 'reports an error if two or more state transitions define "name:self"' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions']['create'].merge!({ 'name' => 'self' })
      end
      @errors = expected_output(:error, 'states.name_self_exception', filename: filename,
        section: :states, sub_header: :error, state: 'collection')
    end

    it 'reports an error if there are duplicated "name" properties per state' do
      @descriptor = drds_descriptor.tap do |document|
        document['resources']['drds']['states']['collection']['transitions']['search'].merge!({ 'name' => 'transition' })
        document['resources']['drds']['states']['collection']['transitions']['create'].merge!({ 'name' => 'transition' })
      end
      @errors = expected_output(:error, 'states.name_duplicated_exception', filename: filename,
        section: :states, sub_header: :error, state: 'collection', transition: 'transition') <<
          expected_output(:warning, 'states.no_self_property', resource: 'drds', state: 'collection',
        transition: 'search', sub_header: :warning) <<
          expected_output(:warning, 'states.no_self_property', resource: 'drds', state: 'collection',
        transition: 'create')
    end

    context 'an external profile' do
      let(:external_url) { 'http://schema.org/Something' }

      it 'reports no errors when it is already downloaded to disk' do
        @descriptor = drds_descriptor
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports an error if its url points to an invalid address' do
        stub_profile_request(404)
        @descriptor = drds_descriptor.tap do |document|
          external_location = [{ 'location' => external_url }]
          document['resources']['drd']['states']['activated']['transitions']['repair-history']['next'] = external_location
        end
        @errors = expected_output(:error, 'states.invalid_external_location', link: external_url,
          secondary_descriptor: 'drd', state: 'activated', transition: 'leviathan', filename: filename, section: :states,
          sub_header: :error) <<
          expected_output(:error, 'states.invalid_external_location', link: external_url,
            secondary_descriptor: 'drd', state: 'activated', transition: 'repair-history') <<
          expected_output(:error, 'states.invalid_external_location', link: external_url,
            secondary_descriptor: 'drd', state: 'deactivated', transition: 'leviathan')
      end
      
      it "doesn't report an error if its next location is exit" do
        #stub_profile_request(404)
        @descriptor = drds_descriptor.tap do |document|
          external_location = [{ 'location' => 'exit' }]
          document['resources']['drd']['states']['activated']['transitions']['repair-history']['next'] = external_location
        end
        @message = "In file '#{filename}':\n#{I18n.t('aok').green}\n"
      end

      it 'reports a warning if its url has a valid address but is not downloaded to disk' do
        stub_profile_request(200)
        @descriptor = drds_descriptor.tap do |document|
          external_location = [{ 'location' => external_url }]
          document['resources']['drd']['states']['activated']['transitions']['repair-history']['next'] = external_location
        end
        @warnings = expected_output(:warning, 'states.download_external_profile', link: external_url,
          secondary_descriptor: 'drd', state: 'activated', transition: 'leviathan', filename: filename, section: :states,
          sub_header: :warning) <<
          expected_output(:warning, 'states.download_external_profile', link: external_url,
            secondary_descriptor: 'drd', state: 'activated', transition: 'repair-history') <<
          expected_output(:warning, 'states.download_external_profile', link: external_url,
            secondary_descriptor: 'drd', state: 'deactivated', transition: 'leviathan')
      end

      def stub_profile_request(status)
        stub_request(:get, external_url).with(:headers => {'Accept' => '*/*', 'User-Agent' => 'Ruby'}).
          to_return(:status => status, :body => "", :headers => {})
        allow_any_instance_of(Crichton::Lint::StateTransitionDecorator).to receive(:next_state_location).and_return(external_url)
      end
    end
  end
end
