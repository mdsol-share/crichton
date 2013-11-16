require 'crichton/lint/base_validator'

module Crichton
  module Lint
    class DatalistsValidator < BaseValidator
      section :datalists

      def validate
        @resource_descriptor.datalists.each do |key, value|
          if value
            add_error('datalists.invalid_value_type', key: key) unless valid_data_list_value?(value)
          else
            add_error('datalists.value_missing', key: key)
          end
        end
      end

      private
      def has_datalist_section?
        resource_descriptor.descriptor_document[:datalist.to_s]
      end

      def valid_data_list_value?(value)
        value.is_a?(Hash) || value.is_a?(Array)
      end
    end
  end
end