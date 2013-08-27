require 'crichton'

module Lint
  class BaseValidator

    attr_accessor :errors
    attr_accessor :warnings
    cattr_accessor :validator_subclasses

    self.validator_subclasses = {}

    def initialize(resource_desc = {})
      @warnings = []
      @errors = []
      @resource_descriptor = resource_desc
      setup_internationalization_messages
    end

    def add_error(message, options = {})
      @errors << I18n.t(message, options)
    end

    def add_warning(message, options = {})
      @warnings << I18n.t(message, options)
    end

    #When the dust settles, print out the results of the lint analysis
    def report
      errors.each { |error| puts "\tERROR: " << error }
      warnings.each { |warning| puts "\tWARNING: " << warning }
    end

    def validate(options = {})
      raise "Abstract method #validate must be overridden in #{self.class.name}."
    end

    def found_issues?
      errors.any? || warnings.any?
    end

    protected
    # here we use il8n to spit out all error and warning messages found in eng.yml
    def setup_internationalization_messages
      I18n.load_path = [File.dirname(__FILE__)+'/eng.yml']
      I18n.default_locale = 'eng'
    end

    def secondary_descriptors
      @resource_descriptor.descriptors
    end
  end
end

