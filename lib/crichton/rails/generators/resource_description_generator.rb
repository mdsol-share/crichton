require 'rails/generators'

module Crichton
  # registers a Generator with Rails invoked as crichton:resource_description
  class ResourceDescriptionGenerator <  Rails::Generators::Base
    # The source directory for our templates
    source_root File.expand_path("../", __FILE__)

    argument :resource_name, type: :string, desc: "The name for the resource"
    argument :collection_name, type: :string, desc: "The name for the collection resource"
    argument :api_dir, type: :string, default: 'api_descriptors', desc: 'directory for our api docs'

    desc "This generator will generate a resource description file."
    def create_description
      copy_file "template.yaml", filename
      gsub_file filename, "{resource_name}", resource_name
      gsub_file filename, "{collection_name}", collection_name
    end

    private
    def filename
       "#{api_dir}/#{collection_name}.yaml"
     end
  end
end
