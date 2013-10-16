require 'rspec/core/rake_task'

desc 'Executes all specs'
namespace :spec do
  RSpec::Core::RakeTask.new(:all_specs)
end
