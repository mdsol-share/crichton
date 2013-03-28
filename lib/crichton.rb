require 'crichton/descriptors/resource'

module Crichton
  ##
  # Clears any registered resource descriptors.
  def self.clear_resource_descriptors
    @registered_resource_descriptors = nil
    Descriptors::Resource.clear
  end

  ##
  # Returns the registered resources.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @@return [Hash] The registered resource descriptors, if any?
  def self.resource_descriptors
    unless @registered_resource_descriptors
      unless Descriptors::Resource.registered_resources?
        if location = config.resource_descriptors_location
          Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f| 
            Descriptors::Resource.register(YAML.load_file(f))
          end
        end
      end
      @registered_resource_descriptors = Descriptors::Resource.registered_resources
    end
    @registered_resource_descriptors
  end
end
