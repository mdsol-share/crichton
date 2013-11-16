require 'yaml'
require 'i18n'
require 'active_support/all'
require 'crichton/descriptor'
require 'crichton/lint/resource_descriptor_validator'
require 'crichton/lint/states_validator'
require 'crichton/lint/descriptors_validator'
require 'crichton/lint/protocol_validator'
require 'crichton/lint/datalists_validator'
require 'colorize'

module Crichton
  module Lint

    # check for a variety of errors and other syntactical issues in a resource descriptor file's contents
    def self.validate(filename, options = {})
      # first check for yml compliance. If the yml file is not correctly formed, no sense of continuing.
      begin
        yml_output = YAML.load_file(filename)
        resource_descriptor = Crichton::Descriptor::Resource.new(yml_output)
      rescue StandardError => e
        puts I18n.t('catastrophic.cant_load_file', exception_message: e.message).red
        return
      end

      # the resource descriptor validator checks a lot of top level resource issues
      resource_validator = ResourceDescriptorValidator.new(resource_descriptor, filename, options)
      resource_validator.validate

      # output filename unless there are no non-text options (strict, error_count, warning_count)
      puts "In file '#{filename}':" unless non_output?(options)

      unless resource_validator.errors.empty?
        if options[:strict]
          return false
        elsif options[:count] == :error
          return resource_validator.errors.count
        else
          # any errors caught at this point are so catastrophic that it won't be useful to continue
          resource_validator.report
          return [resource_validator]
        end
      end

      validators = []

      validators << StatesValidator.new(resource_descriptor, filename, options)
      validators << DescriptorsValidator.new(resource_descriptor, filename, options)
      validators << ProtocolValidator.new(resource_descriptor, filename, options)
      validators << DatalistsValidator.new(resource_descriptor, filename, options)

      validators.each do |validator|
        validator.validate
        validator.report unless non_output?(options)
      end

      if options[:strict]
        return validators.all? { |validator| validator.errors.empty? }
      elsif count_option?(options)
        return error_or_warning_count(options, validators)
      else
        puts I18n.t('aok').green unless errors_and_warnings_found?(validators)

        validators << resource_validator
      end
    end

    def self.validate_all(options = {}, validator_returns = [])
      if File.exists?(location = Crichton.descriptor_location)
        Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f|
          validator_returns << self.validate(f, options)
          if options[:strict]
            return false unless validator_returns.all?
          else
            puts "\n" unless non_output?(options)
          end
        end
        non_output?(options) ? all_option_return(validator_returns, options) : validator_returns
      else
        raise "No resource descriptor directory exists. Default is #{Crichton.descriptor_location}."
      end
    end

    def self.version
      puts "Crichton version: #{Crichton::VERSION::STRING}\n\n"
    end

    private
    def self.count_option?(options)
      options[:count] == :error || options[:count] == :warning
    end

    def self.error_or_warning_count(options, validators)
      options[:count] == :error ? error_count(validators) : warning_count(validators)
    end

    def self.error_count(validators)
      validators.map(&:error_count).reduce(0, :+)
    end

    def self.warning_count(validators)
      validators.map(&:warning_count).reduce(0, :+)
    end

    def self.errors_and_warnings_found?(validators)
      validators.any? { |validator| validator.issues? }
    end

    def self.non_output?(options)
      options[:strict] || count_option?(options)
    end

    def self.all_option_return(validator_returns, options)
      return true if options[:strict]
      validator_returns.reduce(0, :+ )
    end

    def self.load_translation_file
      I18n.load_path = [File.join(File.dirname(__FILE__), '/lint/en.yml')]
      I18n.default_locale = 'en'
    end

    self.load_translation_file
  end
end
