require 'rake'
require 'rake/clean'

begin
  namespace :alps do
    desc "Generate ALPS profile documents"
    task :generate_profiles do
      directory = 'alps_profiles'
      Dir::mkdir(directory) unless Dir.exists?(directory)
      Crichton.raw_profile_registry.keys.each do |key|
        %w(xml json).each do |ext|
          doc = Crichton.raw_profile_registry[key].send("to_#{ext}")
          File.open(File.join(directory, "#{key}_profile.#{ext}"), 'w') { |f| f.write(doc) }
        end
      end
    end
  end
end
