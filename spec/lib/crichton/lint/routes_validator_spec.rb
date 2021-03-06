require 'spec_helper'
require 'crichton/lint'

describe Crichton::Lint::StatesValidator do
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

    it 'reports error when route does not have controller property' do
        @descriptor['routes']['create'].except!('controller')
      @errors = expected_output(:error, 'routes.missing_key', resource: 'DRDs', key: 'controller', route: 'create',
        filename: filename, section: :routes, sub_header: :error)
    end

    it 'reports error when route does not have action property' do
        @descriptor['routes']['create'].except!('action')
      @errors = expected_output(:error, 'routes.missing_key', resource: 'DRDs', key: 'action', route: 'create',
        filename: filename, section: :routes, sub_header: :error)
    end

    it 'reports error when there is no corresponding transition in protocols section' do
        @descriptor['routes'].merge!({ 'create2' => { 'controller' => 'drds', 'action' => 'create2' } })
      @errors = expected_output(:error, 'routes.missing_protocol_transitions', resource: 'DRDs', route: 'create2',
        filename: filename, section: :routes, sub_header: :error)
    end

    it 'reports error when there is no corresponding transition in routes section' do
        @descriptor['routes'].except!('create')
      @errors = expected_output(:error, 'routes.missing_route', resource: 'DRDs', transition: 'create',
        filename: filename, section: :routes, sub_header: :error)
    end
    
    it 'reports error when there is no corresponding transition in routes section' do
        @descriptor['routes'].except!('create')
      @errors = expected_output(:error, 'routes.missing_route', resource: 'DRDs', transition: 'create',
        filename: filename, section: :routes, sub_header: :error)
    end
  end
end