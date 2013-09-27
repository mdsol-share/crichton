require 'yaml'
require 'i18n'
require 'active_support/all'
require 'crichton/descriptor'
require 'lint/resource_descriptor_validator'
require 'lint/states_validator'
require 'lint/descriptors_validator'
require 'lint/protocol_validator'

module Lint
  # check for a variety of errors and other syntactical issues in a resource descriptor file's contents
  def self.validate(filename)

    if OPTS[:version]
      puts "Crichton version: #{Crichton::VERSION::STRING}"
      exit
    end

    # Initialize lint messages
    I18n.load_path = [File.dirname(__FILE__)+'/lint/eng.yml']
    I18n.default_locale = 'eng'

    # first check for yml compliance. If the yml file is not correctly formed, no sense of continuing.
    begin
      yml_output = YAML.load_file(filename)
      resource_descriptor = Crichton::Descriptor::Resource.new(yml_output)
    rescue StandardError => e
      puts I18n.t('catastrophic.cant_load_file', filename: filename, exception_message: e.message)
      return
    end

    # the resource descriptor validator checks a lot of top level resource issues
    resource_validator = ResourceDescriptorValidator.new(resource_descriptor, filename)
    resource_validator.validate

    if options[:strict]
      return true if resource_validator.errors.any?
    else
      puts "In file '#{filename}':"

      if resource_validator.errors.any?
        # any errors caught at this point are so catastrophic that it won't be useful to continue
        resource_validator.report
        return [resource_validator]
      end
    end

    validators = []

    validators << StatesValidator.new(resource_descriptor, filename)
    validators << DescriptorsValidator.new(resource_descriptor, filename)
    validators << ProtocolValidator.new(resource_descriptor, filename)

    validators.each do |validator|
      validator.validate
      validator.report unless OPTS[:strict]
    end

    if options[:strict]
      return true if resource_validator.errors.any?
    else
      puts I18n.t('aok') unless errors_and_warnings_found?(validators)

      validators << resource_validator
    end
  end

  private
  def self.errors_and_warnings_found?(validators)
    validators.any? { |validator| validator.issues? }
  end
end
