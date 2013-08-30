require 'lint/base_validator'

module Lint

  class ResourceDescriptorValidator < BaseValidator
    MAJOR_SECTIONS = %w(states descriptors protocols)

    def validate
      check_for_major_sections

      check_for_top_level_properties

      #6 save off resource names, major foobar if no secondary resources are found
      add_error('catastrophic.no_secondary_descriptors') if secondary_descriptors.empty?
    end

    private
    def check_for_major_sections
      # Using Yaml output, check for whoppers first
      MAJOR_SECTIONS.each do |section|
        unless resource_descriptor.descriptor_document[section]
          add_error('catastrophic.section_missing', section: section, filename: filename)
        end
      end
    end

    def check_for_top_level_properties
      add_error('catastrophic.missing_main_id', filename: filename) unless resource_descriptor.id
      add_warning('profile.missing_version', filename: filename) unless resource_descriptor.version
      add_error('profile.missing_doc', filename: filename) unless resource_descriptor.doc
      #Don Demeter may not like these
      add_error('profile.missing_self', filename: filename) unless resource_descriptor.links['self'].href
      add_error('profile.missing_help', filename: filename) unless resource_descriptor.links['help'].href
    end
  end
end

