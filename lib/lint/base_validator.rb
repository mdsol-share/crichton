require 'crichton'

module Lint
  class BaseValidator

    attr_accessor :errors
    attr_accessor :warnings
    attr_reader :secondary_descriptor_keys
    attr_accessor :registry
    cattr_accessor :validator_subclasses

    self.validator_subclasses = {}

    def initialize( registry = {})
      @warnings = []
      @errors = []
      @registry = registry
      setup_internationalization_messages
    end

    # here we use il8n to spit out all error and warning messages found in config/llocales/eng.yml
    def setup_internationalization_messages
      I18n.load_path = [File.dirname(__FILE__)+'/../../config/locales/eng.yml']
      I18n.default_locale='eng'
    end

    def add_to_errors(message, options = {})
      @errors << I18n.t(message, options)
    end

    def add_to_warnings(message, options = {})
      @warnings << I18n.t(message, options)
    end

    # helper method to return the 1-N secondary descriptor found in the resource descriptor file
    def secondary_descriptor_keys
      @registry.keys
    end

    #When the dust settles, print out the results of the lint analysis
    def report_lint_issues
      if errors.any?
        errors.each do |error|
          puts "\tERROR: " << error
        end
      end

      if warnings.any?
        warnings.each do |warning|
          puts "\tWARNING: " <<warning
        end
      end
    end

    # CLASS LEVEL FACTORY METHODS CALLED BY ResourceDescriptorValidator

    # build all validators by names supplied to us
    def self.build_validators(klass_names, registry)
      klass_names.each do |klass_name|
        klass = self.create(klass_name, registry)
        #register the real instance of the object
        self.register_validator(klass_name, klass)
        end
    end

    # creator method to instantiate the real instance of the subclass
    def self.create(type, registry)
        return self.validator_subclasses[type].new(registry) if self.validator_subclasses[type]
        raise "No such type #{type}"
    end

    # this is a CALLBACK upon object declaration, prior to object creation.
    def self.inherited(subclass)
      ## remove the "Lint::" module name for later matching in create(). Should do a regex, but...
      self.validator_subclasses[subclass.name.split("::")[1]] = subclass
     end

    # put the object INSTANCE into the hash as a value
    def self.register_validator(klassname, klass)
      self.validator_subclasses[klassname] = klass
    end
  end
end