require 'rake'

desc "Generate lint validation of a resource descriptor file"
namespace :crichton do
  task :lint, :rd_file do |t, args|
     require 'lint'
     puts "Linting file: "+args[:rd_file]
     begin
        Lint.validate args[:rd_file]
     rescue StandardError => e
       puts "Lint exception: #{e.message}"
    end
  end
end

