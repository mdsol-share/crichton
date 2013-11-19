# class to valid the integrity of field_type names, validator names and allowed validator per field_type
module Crichton
  module Lint
    # class to lint check field_type descriptor options
    class FieldTypeValidator

      # valid field_type keywords
      def self.field_types
        @field_types ||=
          %w(text search email tel url datetime date time month week datetime-local number boolean select)
      end

      # valid types of field_types
      def self.validator_types
        @val_types ||= %w(required pattern maxlength min max)
      end

      # hash of arrays of allowable field_type validators keynames by validator_type
      def self.allowable_validators
        @allowable_validators ||= {pattern: %w(text search email tel url), maxlength: %w(text url),
          min: %w(datetime date time month week datetime-local number),
          max: %w(datetime date time month week datetime-local number),
          required: self.field_types}
      end

      ##
      # standard lint validate method
      #
      # @param [Crichton::Lint::DescriptorsValidator] descriptor_validator  option validator object
      # @param [Crichton::Descriptor::Detail] descriptor current descriptor object
      def self.validate(descriptor_validator, descriptor)
        return unless descriptor.field_type

        if field_types.include?(descriptor.field_type)
          validate_field_validators(descriptor_validator, descriptor)
        else
          descriptor_validator.add_error('descriptors.invalid_field_type', id: descriptor.id, field_type:
            descriptor.field_type)
        end
      end

      ##
      # main method to perform validation on field_type options
      #
      # @param [Crichton::Lint::DescriptorsValidator] descriptor_validator  option validator object
      # @param [Crichton::Descriptor::Detail] descriptor current descriptor object
      def self.validate_field_validators(descriptor_validator, descriptor)
        descriptor.validators.keys.each do |validator|
          if validator_types.include?(validator)
            allowable_validators_check(descriptor_validator, descriptor, validator)
          else
            descriptor_validator.add_error('descriptors.invalid_field_validator', id: descriptor.id, field_type:
              descriptor.field_type, validator: validator)
          end
        end
      end

      ##
      # check to see if the keyword child elements for validators are correct
      #
      # @param [Crichton::Lint::DescriptorsValidator] descriptor_validator  option validator object
      # @param [Crichton::Descriptor::Detail] descriptor current descriptor object
      # @param [String] validator field_type validator key name
      def self.allowable_validators_check(descriptor_validator, descriptor, validator)
        # test for allowable validator for this field_type
        unless allowable_validators[validator.to_sym].include?(descriptor.field_type)
          descriptor_validator.add_error('descriptors.not_permitted_field_validator', id: descriptor.id, field_type:
            descriptor.field_type, validator: validator)
        end
      end
    end
  end
end
