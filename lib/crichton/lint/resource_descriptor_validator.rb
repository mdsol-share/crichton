require 'crichton/lint/base_validator'

module Crichton
  module Lint
    # class to lint validate with respect to catastrophic errors
    class ResourceDescriptorValidator < BaseValidator
      # @private the three major mandatory sections in a resource descriptor document
      MAJOR_SECTIONS = %w(descriptors protocols)
      section :catastrophic

      # standard lint validate method
      def validate
        check_for_major_sections

        check_for_top_level_properties

        #6 save off resource names, major foobar if no secondary resources are found
        add_error('catastrophic.no_secondary_descriptors') if secondary_descriptors.empty?
      end

      private

      # check to see if one of the major mandatory sections exist within a resource descriptor document
      def check_for_major_sections
        # Using Yaml output, check for whoppers first
        MAJOR_SECTIONS.each do |section|
          unless resource_descriptor.descriptor_document[section]
            add_error('catastrophic.section_missing', missing_section: section, section: :catastrophic)
          end
        end
      end

      # the top level profile attribute check
      def check_for_top_level_properties
        add_error('catastrophic.missing_main_id') unless resource_descriptor.id
        add_warning('profile.missing_version') unless resource_descriptor.version
        add_error('profile.missing_doc') unless resource_descriptor.doc
        add_error('profile.missing_self') unless resource_descriptor.links['profile'].href
        add_error('profile.missing_help') unless resource_descriptor.links['help'].href
      end
    end
  end
end
