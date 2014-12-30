SPEC_DIR = File.expand_path("..", __FILE__)
lib_dir = File.expand_path("../lib", SPEC_DIR)
LINT_DIR = File.expand_path("../lib/crichton/lint", SPEC_DIR)
DISCOVERY_DIR = File.expand_path("../lib/crichton/discovery", SPEC_DIR)
LINT_FILENAME = 'drds_lint.yml'

SPECS_TEMP_DIR = 'tmp'

$LOAD_PATH.unshift(lib_dir)
$LOAD_PATH.uniq!

require 'rspec'
#DIE require 'rspec/collection_matchers'
require 'bundler'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
require 'webmock/rspec'
require 'simplecov'
require 'json_spec'
require 'timecop'
require 'crichton'


SimpleCov.start do
  add_filter 'spec/'
  # Effectively ignores a require in a railtie.  Rake tasks themselves are tested elsewhere.
  add_filter 'lib/crichton/rake_lint.rb'
end

Bundler.setup

# Delete the tmp specs directory and all its contents.
require 'fileutils'
FileUtils.rm_r SPECS_TEMP_DIR if File.exists?(SPECS_TEMP_DIR)
Dir.mkdir SPECS_TEMP_DIR

CONF_DIR = File.join('spec', 'fixtures', 'config')
ROOT_DIR = SPEC_DIR

#DIE require File.expand_path("../integration/crichton-demo-service/config/environment", __FILE__)
#DIE require 'rspec/rails'
Dir["#{SPEC_DIR}/support/*.rb"].each { |f| require f }
#DIE CRICHTON_DEMO_SERVICE = Rails
Crichton::config_directory = CONF_DIR
#DIE #Crichton::root = ROOT_DIR
#DIE #Crichton.instance_variable_set(:@root, Dir.pwd)
Crichton.logger = ::Logger.new(STDOUT)
Crichton.logger.level = Logger::ERROR # Avoid non-error to populate the terminal when running specs

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random' unless ENV['RANDOMIZE'] == 'false'

  config.include Support::Helpers
  config.include Support::ALPS
  config.include Support::DRDHelpers
  #DIE config.infer_spec_type_from_file_location!

  config.before(:each) do
    stub_configured_profiles
    Crichton.config_directory = CONF_DIR
    Crichton.descriptor_registry
  end

  config.after(:each) do
    # We shall never depend on Rails, so help me specs.
    Object.send(:remove_const, :Rails) if Object.const_defined?(:Rails)
    Crichton.reset
    Crichton.clear_config
  end

  config.include JsonSpec::Helpers
end
