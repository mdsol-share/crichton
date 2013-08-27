require 'yaml'
require 'i18n'
require 'crichton'
require 'lint/resource_descriptor_validator'
require 'lint/states_validator'
require 'lint/descriptors_validator'
require 'lint/protocol_validator'

module Lint
  # check for a variety of errors and other syntactical issues in a resource descriptor file's contents
  def self.validate(filename)

    setup_internationalization_messages

    # first check for yml compliance. If the yml file is not correctly formed, no sense of continuing.
    begin
      yml_output = YAML.load_file(filename)
      resource_descriptor = Crichton::Descriptor::Resource.new(yml_output)
    rescue Exception => e
      puts I18n.t('catastrophic.cant_load_file', :filename => filename, :exception_message => e.message)
      return
    end

    # the resource descriptor validator checks a lot of top level resource issues
    resource_validator = ResourceDescriptorValidator.new(resource_descriptor, filename, yml_output)
    resource_validator.validate()

    if resource_validator.errors.any?
      # any errors caught at this point  are so catastrophic that it won't be useful to continue
      resource_validator.report
      return [resource_validator]
    end

    validators = []
    validators << resource_validator

    validators << StatesValidator.new(resource_descriptor)
    validators << DescriptorsValidator.new(resource_descriptor)
    validators << ProtocolValidator.new(resource_descriptor)

      validators.tap do |validators|
        validators.each do |validator|
            validator.validate unless validator.class.name == 'Lint::ResourceDescriptorValidator'
            validator.report
          end
      end

    puts I18n.t('aok') unless errors_and_warnings_found?(validators)
  end

  def self.setup_internationalization_messages
    I18n.load_path = [File.dirname(__FILE__)+'/lint/eng.yml']
    I18n.default_locale = 'eng'
  end


  def self.errors_and_warnings_found?(validators)
    validators.each do |validator|
          return true if validator.found_issues?
    end
    false
  end
end

