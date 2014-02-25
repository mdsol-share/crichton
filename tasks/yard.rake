require 'rake'
require 'rake/clean'

CLOBBER.include('.yardoc', 'yardoc')
CLOBBER.uniq!

begin
  require 'yard'
  require 'yard/rake/yardoc_task'

  namespace :doc do
    desc 'Generate Yardoc documentation'
    YARD::Rake::YardocTask.new
  end

  desc 'Alias to doc:yard'
  task 'doc' => 'doc:yard'
rescue LoadError
  # If yard isn't available, it's not the end of the world
  desc 'Alias to doc:rdoc'
  task 'doc' => 'doc:rdoc'
end
