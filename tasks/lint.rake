require 'rake'
require 'colorize'

desc "Generate lint validation of a resource descriptor file"
namespace :crichton do
  task :lint, [:file_or_all, :lint_option] => :environment do |t, args|
    require 'lint'
    begin
      option = args[:lint_option]  ? Hash[args[:lint_option].to_sym, true] : {}

      Lint.version if option[:version]

      unless option[:strict]
        puts args[:file_or_all] == 'all' ? "Linting all descriptor files" : "Linting file:'#{args[:file_or_all]}'"
        puts "Options: #{option.keys.first.to_s}" unless option.empty?
      end

      if args[:file_or_all] == 'all'
        retval = Lint.validate_all(option)
      else
        retval = Lint.validate(args[:file_or_all], option)
      end
      puts retval ? "#{retval}\n".green : "#{retval}\n".red if option[:strict]
    rescue StandardError => e
      puts "Lint exception: #{e.message}"
    end
  end
end
