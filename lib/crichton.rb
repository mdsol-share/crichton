require 'crichton/serialization/alps'
require 'crichton/descriptor/base'
require 'crichton/descriptor/http'
require 'crichton/descriptor/profile'
require 'crichton/descriptor/detail'
require 'crichton/descriptor/resource'
require 'crichton/descriptor/state'
require 'crichton/descriptor/state_transition'

module Crichton
  ##
  # Clears any registered resource descriptors.
  def self.clear_registry
    @registry = nil
    Descriptor::Resource.clear_registry
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
      unless Descriptor::Resource.registrations?
        if location = config.resource_descriptors_location
          Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f| 
            Descriptor::Resource.register(YAML.load_file(f))
          end
        end
      end
      @registry = Descriptor::Resource.registry
    end
    @registry
  end
end

# YARD macros definitions for re-use in different classes. These must defined in the first loaded class to
# be available in other classes.
#
# @!macro array_reader
#   @!attribute [r] $1
#   Returns the $1 of the underlying descriptor document.
#   @return [Array] The descriptor $1.
#
# @!macro string_reader
#   @!attribute [r] $1
#   Returns the $1 of the underlying descriptor document.
#   @return [String] The descriptor $1.
#
# @!macro hash_reader
#   @!attribute [r] $1
#   Returns the $1 of the underlying descriptor document.
#   @return [Hash] The descriptor $1.
#
# @!macro object_reader
#   @!attribute [r] $1
#   Returns the $1 of the underlying descriptor document.
#   @return [Object] The descriptor $1.
