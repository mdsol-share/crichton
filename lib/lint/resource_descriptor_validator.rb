require 'yaml'
require 'i18n'
require 'crichton'
require 'lint/base_validator'

module Lint

  class ResourceDescriptorValidator < BaseValidator
    MAJOR_SECTIONS = %w(states descriptors protocols)

    def initialize(resource_descriptor, filename, yml_output)
      super(resource_descriptor)
      @filename = filename
      @yml_output = yml_output
    end

    def validate()

      check_for_major_sections

      check_for_top_level_properties

      #6 save off resource names, major foobar if no secondary resources are found
      if secondary_descriptors.empty?
        add_error('catastrophic.no_secondary_descriptors')
      end
    end

    def check_for_major_sections()
      # Using Yaml output, check for whoppers first
      MAJOR_SECTIONS.each do |section|
        if @yml_output[section].nil?
          add_error('catastrophic.section_missing', :section => section, :filename => @filename)
        end
      end
    end

    def check_for_top_level_properties
      add_error('catastrophic.missing_main_id') unless @resource_descriptor.id
      add_warning('profile.missing_version') unless @resource_descriptor.version
      add_error('profile.missing_doc') unless @resource_descriptor.doc
      #Don Demeter may not like these
      add_error('profile.missing_self') unless @resource_descriptor.links['self'].href
      add_error('profile.missing_help') unless @resource_descriptor.links['help'].href
    end
  end
end

