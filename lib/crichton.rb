require 'active_support/all'
require 'crichton/configuration'
require 'crichton/registry'
require 'crichton/descriptor'
require 'crichton/errors'
require 'crichton/dice_bag/template'
require 'crichton/representor'
require 'crichton/alps/deserialization'

if defined?(Rails)
  require 'crichton/rake_lint'
  require 'core_ext/action_controller/responder'
end

module Crichton
  ##
  # Logger
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    # This is probably not to be the final outcome - but for now this defaults to Rails.logger or STDOUT.
    # TODO: Add Sinatra support. I couldn't find any reliable enough way - it seems that there is no standard way
    # of accessing the logger like there is for Rails.
    @logger ||= if Object.const_defined?(:Rails)
        Rails.logger
      #Add other environments as needed here!
      else
        ::Logger.new(STDOUT)
      end
  end


  ##
  # Clears any registered resource descriptors.
  def self.clear_registry
    @registry = nil
  end

  ##
  # Explicitly initialize the registry with a particular document (or file name)
  #
  # This is mostly relevant for tests or situations in which you do not want the auto-loading to be performed.
  # @param descriptor_document [Hash or String] Descriptor document hash (loaded YML file) or filename to be registered.
  def self.initialize_registry(descriptor_document)
    @registry = Crichton::Registry.new(:automatic_load => false)
    @registry.register_single(descriptor_document)
  end

  ##
  # Returns the registered resources - version that has local resources de-referenced.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @return [Hash] The registered resource descriptors, if any?
  def self.descriptor_registry
    @registry ||= Crichton::Registry.new
    @registry.descriptor_registry
  end

  ##
  # Returns the registered resources - version that does not have the local resources de-referenced.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @return [Hash] The registered resource descriptors, if any?
  def self.raw_descriptor_registry
    @registry ||= Crichton::Registry.new
    @registry.raw_descriptor_registry
  end

  def self.values_registry
    @registry ||= Crichton::Registry.new
    @registry.values_registry
  end

  ##
  # external_descriptor_document_urls
  def self.external_descriptor_document_urls
    @registry ||= Crichton::Registry.new
    @registry.descriptor_registry
    descriptor_documents = @registry.external_descriptor_documents
    descriptor_documents.keys if descriptor_documents
  end

  ##
  # Returns the registered resources - toplevel version that does not have the local resources de-referenced.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @return [Hash] The registered resource descriptors, if any?
  def self.raw_profile_registry
    @registry ||= Crichton::Registry.new
    @registry.raw_profile_registry
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
      raise "No crichton.yml file found in the configuration directory: #{config_directory}. Tried #{config_file}."
    end
  end

  ##
  # @!attribute config_directory
  # The directory where the crichton.yml configuration file is located. Modify this value in an initializer to
  # set a different path to the configuration.
  #
  # @example
  #   Crichton.config_directory #=> 'config'
  #
  #   Crichton.config_directory = 'other_config
  #   Crichton.config_directory #=> 'other_config'
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
  # @!attribute config_directory
  # The directory where the crichton.yml configuration file is located. Modify this value in an initializer to
  # set a different path to the configuration.
  #
  # @example
  #   Crichton.descriptor_directory #=> 'api_descriptors'
  #
  #   Crichton.config_directory = 'other_api_descriptors'
  #   Crichton.config_directory #=> 'other_api_descriptors'
  #
  # @return [String] The descriptors directory. Default is root/api_descriptors.
  def self.descriptor_directory
    @descriptor_directory ||= 'api_descriptors'
  end

  def self.descriptor_directory=(directory)
    @descriptor_location = nil
    @descriptor_directory = directory
  end

  def self.descriptor_location
    @descriptor_location ||= File.join(root, descriptor_directory)
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
