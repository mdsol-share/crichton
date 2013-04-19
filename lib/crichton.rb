require 'crichton/configuration'
require 'crichton/descriptor/resource'
require 'crichton/dice_bag/template'

module Crichton
  ##
  # Clears any registered resource descriptors.
  def self.clear_registry
    @registry = nil
    Descriptor::Resource.clear_registry
  end
  
  ##
  # Clears the config and config_directory so that they reset themselves.
  def self.clear_config
    @config = nil
    @root = nil
    self.config_directory = nil
  end
  
  ##
  # Returns the configuration specified in the crichton.yml file in the configuration directory.
  #
  # @return [Configuration] The configuration instance.
  def self.config
    @config ||= if File.exists?(config_file)
      environment = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      Configuration.new(YAML.load_file(config_file)[environment])
    else
      raise "No crichton.yml file found in the configuration directory: #{config_directory}."
    end
  end
  
  ##
  # @!attribute config_directory
  # The directory where the crichton.yml configuration file is located. Modify this value in an initializer to
  # set a different path to the configuration.
  #
  # @example
  #   Crichton.config_directory #=> config
  #
  #   Crichton.config_directory = other_config
  #   Crichton.config_directory #=> other_config
  #
  # @return [String] The configuration directory. Default is root/config.
  def self.config_directory
    @config_directory ||= 'config'
  end

  def self.config_directory=(directory)
    @config_file = nil
    @config_directory = directory
  end

  ##
  # @!attribute config_file
  # The fully-qualified path to crichton.yml configuration file.
  #
  # @return [String] The configuration file path.
  def self.config_file
    @config_file ||= File.join(root, config_directory, 'crichton.yml')
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

  ##
  # The root directory of parent project.
  #
  # @return [String] The root directory.
  def self.root
    @root ||= if const_defined?('Rails')
      Rails.root
    elsif const_defined?('Sinatra')
      Sinatra.settings.root
    else
      Dir.pwd
    end
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
