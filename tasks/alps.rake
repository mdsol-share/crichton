require 'rake'
require 'rake/clean'

require 'pry'

begin
  namespace :alps do
    desc "Generate ALPS profile documents"
    task :generate_profiles do
      directory = 'generated_alps_profiles'
      Dir::mkdir(directory) unless Dir.exists?(directory)
      Crichton.descriptor_registry.keys.each do |key|
        f = open(File.join(directory, "#{key}.profile"), 'wb')
        f.write Crichton.descriptor_registry[key].parent_descriptor.to_xml
        f.close
      end
    end
  end
end
