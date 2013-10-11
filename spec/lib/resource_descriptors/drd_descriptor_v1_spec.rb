require 'spec_helper'
require 'lint'

describe 'DRDs resource descriptor' do
  let(:validator) { Lint }
  #   For users of the Crichton gem, change to this line and update <my descriptor_file>
  #   let(:filename) { File.join(Crichton.descriptor_location, <my descriptor file>) }
  #
  let(:filename) { fixture_path('resource_descriptors', 'drds_descriptor_v1.yml') }

  # Lint reports information to stdout. Add the following method if you do not want to see Lint output
  before do
    $stdout.stub(:write)
  end

  it 'exists' do
    File.exists?(filename).should be_true
  end

  it 'contains (6) errors' do
    # TODO should change when we fix up drds_descriptor_v1.yml
    validator.validate(filename, {count: :error}).should == 6
  end

  it 'contains (20) warnings' do
    # TODO should change when we fix up drds_descriptor_v1.yml
    validator.validate(filename, {count: :warning}).should == 20
  end

  it 'passes validation with the --strict option' do
    # TODO should change when we fix up drds_descriptor_v1.yml
    result = validator.validate(filename, {strict: true})
    result.should be_false # should be_true when we fix up drds_descriptor_v1.yml
  end
end
