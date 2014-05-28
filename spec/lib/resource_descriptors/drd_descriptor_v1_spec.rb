require 'spec_helper'
require 'crichton/lint'

describe 'DRDs resource descriptor' do
  let(:validator) { Crichton::Lint }
  #   For users of the Crichton gem, change to this line and update <my descriptor_file>
  #   let(:filename) { File.join(Crichton.descriptor_location, <my descriptor file>) }
  #
  let(:filename) { fixture_path('resource_descriptors', 'drds_descriptor_v1.yml') }

  # Lint reports information to stdout. Add the following method if you do not want to see Lint output
  before do
    allow_any_instance_of(Crichton::ExternalDocumentStore).to receive(:get).and_return('<alps></alps>')
    allow($stdout).to receive(:write)
  end

  it 'exists' do
    expect(File.exists?(filename)).to be_true
  end

  it 'contains the proper number of warnings' do
    expect(validator.validate(filename, {count: :warning})).to eq(0)
  end

  it 'passes validation with the --strict option' do
    expect(validator.validate(filename, {strict: true})).to be_true
  end
end
