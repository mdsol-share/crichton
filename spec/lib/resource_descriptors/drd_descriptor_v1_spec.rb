require 'spec_helper'
require 'rake'
require 'lint'

describe 'validate' do
  let(:validator) { Lint }
  let(:filename) { fixture_path('resource_descriptors', @filename) }
  let(:options) { @options ? @options : {} }

  describe 'inspecting the return value from validation' do
    # Lint reports information to stdout. So when using the direct method and you do not want to see Lint output,
    # add these 2 methods
    before do
      $stdout.stub(:write)
    end

    after do
      rspec_reset
    end

    it 'matches on an error and/or warning count' do
      @filename = 'drds_descriptor_v1.yml'
      validators = validator.validate(filename)
      # Should change when we fix up drds_descriptor_v1.yml
      Lint.error_count(validators).should == 6
      Lint.warning_count(validators).should == 20
    end

    it 'performs a pass/fails test with the --strict option' do
      @filename = 'drds_descriptor_v1.yml'
      result = validator.validate(filename, {strict: true})
      result.should be_false   # should be_true when we fix up drds_descriptor_v1.yml
    end
  end

  context 'when matching stdout response' do
    after do
      validation_report.should == @message
    end

    def validation_report
      capture(:stdout) { validator.validate(filename, options) }
    end

    it 'matches expected error and warnings' do
      @filename = 'drds_descriptor_v1.yml'
      @message = build_error_and_warning_list
    end

    it 'matches expected output for errors only with the --no_warnings option' do
      @filename = 'drds_descriptor_v1.yml'
      @message = build_errors_only_list
      @options = {no_warnings: true}
    end

    it 'matches expected output with the --all option' do
      @filename = 'drds_descriptor_v1.yml'  # filename is ignored in this case
      @message = build_error_and_warning_list
      @options = {all: true}
    end
  end

  context 'using rdlint as a means for validation' do
    before do
      load_lint_translation_file
    end

    after do
      %x(bundle exec rdlint #{@option} #{filename}).should == @expected_rdlint_output
    end

    it 'matches expected output with the -w (--no_warnings) option' do
      @filename = 'drds_descriptor_v1.yml'
      @expected_rdlint_output = build_errors_only_list
      @option = '-w'
    end
  end

  context 'using rake as a means for validation' do
    before do
      load_lint_translation_file
      Rake::Task.define_task(:environment)
    end

    after do
      rake_invocation = @option ? "crichton:lint[#{filename},#{@option}]" : "crichton:lint[#{filename}]"
      capture(:stdout) { Rake.application.invoke_task "#{rake_invocation}" }.should ==
        "Linting file:'#{filename}'\n#{(@option ? "Options: #{@option}\n" : "")}#{@expected_rake_output}"
    end

    it 'matches expected output with the --no_warnings option' do
      @filename = 'drds_descriptor_v1.yml'
      @expected_rake_output = build_errors_only_list
      @option = 'no_warnings'
    end
  end
end

# these methods should become a lot skinnier when we fix up drds_descriptor_v1.yml
def build_error_and_warning_list
  message = expected_output(:error, 'descriptors.property_missing', resource: 'create-drd', prop: 'doc', filename: filename) <<
    expected_output(:error, 'descriptors.property_missing', resource: 'update', prop: 'rt') <<
    expected_output(:error, 'descriptors.property_missing', resource: 'update-drd', prop: 'doc') <<
    expected_output(:error, 'descriptors.property_missing', resource: 'delete', prop: 'rt') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'items', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'search_term', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'create-drd', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-name', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-leviathan_uuid', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-leviathan_health_points', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-leviathan_email', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'leviathan', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'update-drd', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'update-drd', prop: 'href') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-status', prop: 'sample') <<
    expected_output(:warning, 'descriptors.property_missing', resource: 'form-kind', prop: 'sample') <<
    expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'repair-history', protocol: 'http') <<
    expected_output(:error, 'protocols.state_transition_not_found', transition: 'repair-history', protocol: 'http') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'search') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'create') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'show') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'activate') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'deactivate') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'update') <<
    expected_output(:warning, 'protocols.property_missing', property: 'status_codes', protocol: 'http', action: 'delete') <<
    expected_output(:warning, 'protocols.extraneous_props', protocol: 'http', action: 'leviathan-link')
end

def build_errors_only_list
  message = expected_output(:error, 'descriptors.property_missing', resource: 'create-drd', prop: 'doc', filename: filename) <<
    expected_output(:error, 'descriptors.property_missing', resource: 'update', prop: 'rt') <<
    expected_output(:error, 'descriptors.property_missing', resource: 'update-drd', prop: 'doc') <<
    expected_output(:error, 'descriptors.property_missing', resource: 'delete', prop: 'rt') <<
    expected_output(:error, 'protocols.descriptor_transition_not_found', transition: 'repair-history', protocol: 'http') <<
    expected_output(:error, 'protocols.state_transition_not_found', transition: 'repair-history', protocol: 'http')
end


