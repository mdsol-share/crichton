require 'rspec/core/rake_task'

begin
  namespace :spec do
    RSpec::Core::RakeTask.new(:all_specs)
  end
end
