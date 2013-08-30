require 'rake'
require 'rake/clean'

FILEEXTENSION_TO_METHOD_MAPPING = {'xml' => :to_xml, 'json' => :to_json}

begin
  namespace :alps do
    desc "Generate ALPS profile documents"
    task :generate_profiles do
      directory = 'generated_alps_profiles'
      Dir::mkdir(directory) unless Dir.exists?(directory)
      Crichton.descriptor_registry.keys.each do |key|
        FILEEXTENSION_TO_METHOD_MAPPING.each do |ext, methodname|
          f = open(File.join(directory, "#{key}_profile.#{ext}"), 'wb')
          f.write Crichton.descriptor_registry[key].parent_descriptor.send(methodname)
          f.close
        end
      end
    end
  end
end
