require 'crichton'
require 'lint'
require 'i18n'

module Lint
  class BaseValidator

    attr_reader :errors
    attr_reader :warnings
    attr_reader :resource_descriptor
    attr_reader :filename

    def initialize(resource_descriptor, filename)
      @warnings = []
      @errors = []
      @filename = filename
      @resource_descriptor = resource_descriptor
    end

    #When the dust settles, print out the results of the lint analysis
    def report
      errors.each { |error| puts "\tERROR: " << error }
      warnings.each { |warning| puts "\tWARNING: " << warning }
    end

    def validate(options = {})
      raise "Abstract method #validate must be overridden in #{self.class.name}."
    end

    def issues?
      errors.any? || warnings.any?
    end

    protected
    def add_error(message, options = {})
      @errors << I18n.t(message, options)
    end

    def add_warning(message, options = {})
      @warnings << I18n.t(message, options)
    end

    def secondary_descriptors
      resource_descriptor.descriptors
    end
  end
end

