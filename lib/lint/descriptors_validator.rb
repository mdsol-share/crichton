require 'lint/base_validator'

module Lint
  class DescriptorsValidator < BaseValidator

    def validate

      check_for_secondary_descriptor_states
    end

    private
    def check_for_secondary_descriptor_states
      resource_descriptor.descriptors.each do |descriptor|
        add_error('catastrophic.no_descriptors', resource: descriptor[0], filename: filename) if descriptor.descriptors.empty?
      end
    end
  end
end
