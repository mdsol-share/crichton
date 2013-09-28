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
  def self.validate(filename, options = {})

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
    resource_validator = ResourceDescriptorValidator.new(resource_descriptor, filename, options)
    resource_validator.validate

    if options['strict']
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

    validators << StatesValidator.new(resource_descriptor, filename, options)
    validators << DescriptorsValidator.new(resource_descriptor, filename, options)
    validators << ProtocolValidator.new(resource_descriptor, filename, options)

    validators.each do |validator|
      validator.validate
      validator.report unless options['strict']
    end

    if options['strict']
      return no_errors?(validators)
    else
      puts I18n.t('aok') unless errors_and_warnings_found?(validators)

      validators << resource_validator
    end
  end

  def self.validate_all(options = {}, validator_returns = [])
    if File.exists?(location = Crichton.descriptor_location)
      Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f|
        validator_returns << self.validate(f, options)
        if options['strict']
          return false unless retval
        else
          puts "\n"
        end
      end
     options['strict']  ? true : validator_returns
    else
      raise "No resource descriptor directory exists. Default is #{Crichton.descriptor_location}."
    end
  end

  def self.version
    puts "Crichton version: #{Crichton::VERSION::STRING}\n\n"
  end

  private
  def self.errors_and_warnings_found?(validators)
    validators.any? { |validator| validator.issues? }
  end

  def self.no_errors?(validators)
    validators.any? { |validator| validator.errors.any? } ? false : true
  end
end
