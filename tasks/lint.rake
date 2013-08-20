require 'rake'
require 'lint'

desc "Generate lint validation of a resource descriptor file"
namespace :Crichton do
  task :lint, :rd_file do |t, args|
     puts "Linting file: "+args[:rd_file]
     begin
        Lint.validate args[:rd_file]
     rescue Exception => e
       puts "Lint exception: "+e.message
    end
  end
end

