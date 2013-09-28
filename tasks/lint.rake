require 'rake'

desc "Generate lint validation of a resource descriptor file"
namespace :crichton do
  task :lint, [:file_or_all, :lint_options] => :environment do |t, args|
    require 'lint'
    begin
      if args[:lint_options] == 'version'
        Lint.version
      end
      if args[:file_or_all] == 'all'
        puts "Linting all descriptor files"
        puts "Options: #{args[:lint_options]}" if args[:lint_options]
        Lint.validate_all(args[:lint_options] ? args[:lint_options] : {})
      else
        puts "Linting file:'#{args[:file_or_all]}'"
        puts "Options: #{args[:lint_options]}" if args[:lint_options]
        Lint.validate(args[:file_or_all], args[:lint_options] ? args[:lint_options] : {})
      end
    rescue StandardError => e
      puts "Lint exception: #{e.message}"
    end
  end
end
