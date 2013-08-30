require 'rake'
require 'rake/clean'

FILE_EXTENSION_TO_METHOD_MAPPING = {xml: :to_xml, json: :to_json}

begin
  namespace :alps do
    desc "Generate ALPS profile documents"
    task :generate_profiles do
      directory = 'alps_profiles'
      Dir::mkdir(directory) unless Dir.exists?(directory)
      Crichton.descriptor_registry.keys.each do |key|
        FILE_EXTENSION_TO_METHOD_MAPPING.each do |ext, methodname|
          doc = Crichton.descriptor_registry[key].parent_descriptor.send(methodname)
          File.open(File.join(directory, "#{key}_profile.#{ext}"), 'w') { |f| f.write(doc) }
        end
      end
    end
  end
end
