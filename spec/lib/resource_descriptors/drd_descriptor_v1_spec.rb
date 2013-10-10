require 'spec_helper'
require 'lint'

describe 'validate' do
  let(:validator) { Lint }
  #   For users of the Crichton gem, change to this line and update <my descriptor_file>
  #   let(:filename) { File.join(Crichton.descriptor_location, <my descriptor file>) }
  #
  let(:filename) { fixture_path('resource_descriptors', 'drds_descriptor_v1.yml') }

  it 'successfully finds the specified descriptor file' do
    File.exists?(filename).should be_true
  end

  describe 'inspects the return value' do
    # Lint reports information to stdout. Add the following method if you do not want to see Lint output
    before do
      $stdout.stub(:write)
    end

    it 'to match on an error count' do
      # Should change when we fix up drds_descriptor_v1.yml
      validator.validate(filename, {error_count: true}).should == 6
    end

    it 'to match on a warning count' do
      # Should change when we fix up drds_descriptor_v1.yml
      validator.validate(filename, {warning_count: true}).should == 20
    end

    it 'performing a pass/fails test with the --strict option' do
      result = validator.validate(filename, {strict: true})
      result.should be_false   # should be_true when we fix up drds_descriptor_v1.yml
    end

    it 'performing a pass/fail test on all files in the config folder with the --strict and --all options' do
       result = validator.validate(filename, {strict: true, all: true})
       result.should be_false
     end
  end
end
