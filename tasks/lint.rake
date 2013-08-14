require 'rake'

desc "Generate lint validation of a resource descriptor file"
task :lint, [:rd_file] => :environment do |t, args|
   puts "Linting file "+args[:rd_file]
   begin
      Lint.validate args[:rd_file]
   rescue Exception => e
     puts "Lint exception: "+e.message
  end
end

