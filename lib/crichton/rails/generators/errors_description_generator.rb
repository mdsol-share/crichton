require 'rails/generators'

module Crichton

  class ErrorsDescriptionGenerator <  Rails::Generators::Base
    # The source directory for our templates
    source_root File.expand_path("../", __FILE__)

    argument :errors_class_path, type: :string, desc: "The path that the errors class will go to"
    argument :resource_name, default: 'hyper_error', type: :string, desc: "The name for the hypermedia errors resource"
    argument :api_dir, type: :string, default: 'api_descriptors', desc: 'directory for our api docs'

    desc "This generator will generate a errors resource descriptor file and errors class."
    def create_description
      copy_file "errors_template.yaml", yaml_filename
      gsub_file yaml_filename, "{resource_name}", resource_name
      gsub_file yaml_filename, "{resource_capitalize}", resource_name.classify
      copy_file "error_class_template.txt", class_filename
      gsub_file class_filename, "{resource_name}", resource_name
      gsub_file class_filename, "{resource_capitalize}", resource_name.classify
    end

    private
    def yaml_filename
       "#{api_dir}/#{resource_name}.yml"
    end

    def class_filename
      "#{errors_class_path}/#{resource_name}.rb"
    end
  end
end
