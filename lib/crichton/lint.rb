require 'yaml'
require 'i18n'
require 'active_support/all'
require 'crichton/descriptor'
require 'crichton/lint/resource_descriptor_validator'
require 'crichton/lint/states_validator'
require 'crichton/lint/descriptors_validator'
require 'crichton/lint/protocol_validator'
require 'crichton/lint/routes_validator'
require 'colorize'

# Needed to avoid warnings when using this library
I18n.enforce_available_locales = false

module Crichton
  module Lint
    ##
    # check for a variety of errors and other syntactical issues in a resource descriptor file's contents
    #
    # @param [String] filename file to lint validate
    # @param [Hash] options a hash of lint options,
    def self.validate(filename, options = {})
      # first check for yml compliance. If the yml file is not correctly formed, no sense of continuing.
      begin
        registry = Crichton::Registry.new(automatic_load: options[:automatic_load] || false)
        registry.register_single(filename)
        resource_dereferencer = registry.resources_registry[get_resource_id(filename)]
        hash = resource_dereferencer.dereference(registry.dereferenced_descriptors)
        resource_descriptor = Crichton::Descriptor::Resource.new(hash)
      rescue StandardError => e
        puts I18n.t('catastrophic.cant_load_file', exception_message: e.message).red
        puts e.backtrace.join("\n").red
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
      validators << RoutesValidator.new(resource_descriptor, filename, options)

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

    ##
    # validate method when validating all files in the specified config folder (via the '--all' option)
    #
    # @param [Hash] options additional options to the --all option
    # @param [Array] validator_returns a list of return values for linting all files in a config folder
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

    # output the Crichton version via the --version, -v option inl lint
    def self.version
      puts "Crichton version: #{Crichton::VERSION::STRING}\n\n"
    end

    private
    def self.get_resource_id(file)
      hash_descriptor = case file
      when String
        raise ArgumentError, "Filename #{file} is not valid." unless File.exists?(file)
        YAML.load_file(file)
      when Hash
        file
      end
      hash_descriptor['id']
    end

    # used to determine if the ---count option is set
    def self.count_option?(options)
      options[:count] == :error || options[:count] == :warning
    end

    # @return [Integer] either the count of errors or warnings
    def self.error_or_warning_count(options, validators)
      options[:count] == :error ? error_count(validators) : warning_count(validators)
    end

    # @return [Integer] the count of lint errors found
    def self.error_count(validators)
      validators.map(&:error_count).reduce(0, :+)
    end

    # @return [Integer] the count of lint warnings found
    def self.warning_count(validators)
      validators.map(&:warning_count).reduce(0, :+)
    end

    # return [Boolean] determine if any lint  errors or warnings are found
    def self.errors_and_warnings_found?(validators)
      validators.any? { |validator| validator.issues? }
    end

    # determines if the lint options will return text output or no
    def self.non_output?(options)
      options[:strict] || count_option?(options)
    end

    # @return [Boolean, Integer] depending if lint --strict or --count options are set
    def self.all_option_return(validator_returns, options)
      return true if options[:strict]
      validator_returns.reduce(0, :+ )
    end

    # method to load the internationization feature for lint output
    def self.load_translation_file
      I18n.load_path = [File.join(File.dirname(__FILE__), '/lint/en.yml')]
      I18n.default_locale = 'en'
    end

    self.load_translation_file
  end
end
