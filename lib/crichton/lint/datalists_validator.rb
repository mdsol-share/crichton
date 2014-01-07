require 'crichton/lint/base_validator'

module Crichton
  module Lint
    # class for lint validating the DataLists section of a resource descriptor file
    class DatalistsValidator < BaseValidator
      section :datalists

      # standard validation method
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
      # data lists can only be an array or hash, check for that
      def valid_data_list_value?(value)
        value.is_a?(Hash) || value.is_a?(Array)
      end
    end
  end
end
