require 'yaml'
require 'i18n'
require 'crichton'
require 'lint/base_validator'
require 'lint/profile_validator'
require 'lint/states_validator'

module Lint

  class ResourceDescriptorValidator < BaseValidator
    MAJOR_SECTIONS = %w(states descriptors protocols)
    # why this, because hashes are not ordered, and want to invoke these in a particular order
    VALIDATOR_CLASS_NAMES = %w(ProfileValidator StatesValidator)

    def initialize
      super
      @filename = ""
    end

      def validate(filename)
        @filename = filename

        check_for_yaml_compliance

        check_for_registry_compliance

        check_for_major_sections

        # At this point, if  any errors are encountered, they are so massive that it is not worth the continuation of processing
        return unless errors.empty?

        #6 save off resource names, major foobar if no secondary resources are found
        if secondary_descriptor_keys.empty?
          add_to_errors('catastrophic.no_secondary_descriptors')
        end

        # now that we have a registry object, we can create validator objects
        @validator_classes = BaseValidator.build_validators(VALIDATOR_CLASS_NAMES,@registry)

        # fire off each validator in an order that we determine by the class constant
        @validator_classes.each do |validator|
          validator_subclasses[validator].validate
        end
      end

    #
    def check_for_yaml_compliance()
      begin
         @yml_output = YAML.load_file(@filename)
      rescue Exception => e
        add_to_errors('catastrophic.cant_load_file', :filename => @filename, :exception_message => e.message)
       end
    end

    #
    def  check_for_registry_compliance()
      begin
        @registry = Crichton.single_registry(@filename)
      rescue Exception => e
        add_to_errors('catastrophic.cant_register', :filename => @filename, :exception_message => e.message)
      end
    end

    def check_for_major_sections
      # Using Yaml output, check for whoppers first
      MAJOR_SECTIONS.each do |section|
        if @yml_output[section].nil?
          errors << I18n.t('catastrophic.section_missing', :section=> section, :filename => filename)
        end
      end
    end

    def report_lint_issues
      #print out own current errors

      # if others exist, print out their errors

    end
  end
end
