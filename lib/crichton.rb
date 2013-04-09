require 'crichton/descriptors/base'
require 'crichton/descriptors/descriptor'
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
  def self.clear_registry
    @registry = nil
    ResourceDescriptor.clear_registry
  end

  ##
  # Returns the registered resources.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @return [Hash] The registered resource descriptors, if any?
  def self.registry
    unless @registry
      unless ResourceDescriptor.registrations?
        if location = config.resource_descriptors_location
          Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f| 
            ResourceDescriptor.register(YAML.load_file(f))
          end
        end
      end
      @registry = ResourceDescriptor.registry
    end
    @registry
  end
end
