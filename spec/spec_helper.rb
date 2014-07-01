SPEC_DIR = File.expand_path("..", __FILE__)
lib_dir = File.expand_path("../lib", SPEC_DIR)
LINT_DIR = File.expand_path("../lib/crichton/lint", SPEC_DIR)
DISCOVERY_DIR = File.expand_path("../lib/crichton/discovery", SPEC_DIR)

SPECS_TEMP_DIR = 'tmp'

$LOAD_PATH.unshift(lib_dir)
$LOAD_PATH.uniq!

require 'rspec'
require 'debugger'
require 'bundler'
require 'equivalent-xml'
require 'webmock/rspec'
require 'simplecov'
require 'json_spec'

SimpleCov.start
Debugger.start
Bundler.setup

require 'crichton'

# Delete the tmp specs directory and all its contents.
require 'fileutils'
FileUtils.rm_r SPECS_TEMP_DIR if File.exists?(SPECS_TEMP_DIR)
Dir.mkdir SPECS_TEMP_DIR

Dir["#{SPEC_DIR}/support/*.rb"].each { |f| require f }

Crichton::config_directory = File.join('spec', 'fixtures', 'config')

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
  config.include Support::Controllers
  config.include Support::DRDHelpers
  config.include Support::EPHelpers

  config.before(:each) do
    stub_alps_requests
    Crichton.reset
    Crichton.config_directory = File.join('spec', 'fixtures', 'config')
    Crichton.initialize_registry(drds_descriptor)
  end

  config.include JsonSpec::Helpers
end
