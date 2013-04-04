require 'crichton/descriptors/base'
require 'crichton/descriptors/link'
require 'crichton/descriptors/resource'
require 'crichton/descriptors/semantic'
require 'crichton/descriptors/transition'

module Crichton
  
  ##
  # References a semantic descriptor type.
  SEMANTIC = 'semantic'
  
  ##
  # Clears any registered resource descriptors.
  def self.clear_resource_descriptors
    @registered_resource_descriptors = nil
    ResourceDescriptor.clear
  end

  ##
  # Returns the registered resources.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @return [Hash] The registered resource descriptors, if any?
  def self.resource_descriptors
    unless @registered_resource_descriptors
      unless ResourceDescriptor.registered_resources?
        if location = config.resource_descriptors_location
          Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f| 
            ResourceDescriptor.register(YAML.load_file(f))
          end
        end
      end
      @registered_resource_descriptors = ResourceDescriptor.registered_resources
    end
    @registered_resource_descriptors
  end
end
