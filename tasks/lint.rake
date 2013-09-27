require 'rake'

desc "Generate lint validation of a resource descriptor file"
namespace :crichton do
  task :lint, :file_or_all, :lint_options do |t, args|
    require 'lint'
    begin
      if :lint_options == :version ||
        Lint.version
      end
      if :arg1 == :all
        puts "Linting all descriptor files with options: #{:lint_options.inspect}"
        Lint.validate_all[:lint_options]
      else
        puts "Linting file:'#{+args[:file_or_all]}' with options: #{:lint_options.inspect}"
        Lint.validate args[:file_or_all, :lint_options]
      end
    rescue StandardError => e
      puts "Lint exception: #{e.message}"
    end
  end
end

