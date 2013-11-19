module Crichton
  module Lint
    # class to validate all option elements in the descriptor section of a resource descriptor document
    class OptionsValidator
      ##
      # standard lint validate method
      #
      # @param [Crichton::Lint::DescriptorsValidator] descriptor_validator  option validator object
      # @param [Crichton::Descriptor::Detail] descriptor current descriptor object
      def self.validate(descriptor_validator, descriptor)
        return unless raw_options(descriptor)

        raw_options(descriptor).keys.each do |key|
          #1 invalid option name
          unless Crichton::Descriptor::Options::OPTIONS_VALUES.include?(key)
            descriptor_validator.add_error('descriptors.invalid_options_attribute', id: descriptor.id, options_attr:
              key)
          end
        end

        #4, more than one option specified
        if clashing_keys?(raw_options(descriptor))
          descriptor_validator.add_error('descriptors.multiple_options', id: descriptor.id, options_keys:
            raw_options(descriptor).keys.join(', '))
        end

        option_rule_check(descriptor_validator, descriptor)
      end

      private

      # check to see if certain types of options keys exist together under a single descriptor
      def self.clashing_keys?(options)
        (options.keys & %w(href list hash external_list external_hash)).size > 1
      end

      # class that dispatches for a variety of lint validation checks
      def self.option_rule_check(descriptor_validator, descriptor)
        # various rules depending upon the different types of options
        raw_options(descriptor).each do |form_key, value|
          #1-3 missing value for an option
          if %w(id href list hash external_list external_hash).include?(form_key)
            descriptor_validator.add_error('descriptors.missing_options_value', id: descriptor.id, options_attr:
              form_key) unless value
          end

          case form_key
            when 'list'
              #5
              descriptor_validator.add_error('descriptors.invalid_option_enumerator', id: descriptor.id, key_type:
                form_key, value_type: 'hash') if value.is_a?(Hash)
            when 'hash'
              hash_option_check(descriptor_validator, descriptor, form_key, value) if value

            when 'href'
              href_option_check(descriptor_validator, descriptor, form_key, value) if value

            when 'external_list', 'external_hash'
              external_option_check(descriptor_validator, descriptor, form_key, value) if value

            #11 *warning* if value_attribute_name or text_attribute_name does not have a value
            when 'value_attribute_name', 'text_attribute_name'
              descriptor_validator.add_warning('descriptors.missing_options_value', id: descriptor.id, options_attr:
                form_key) unless value
            #12, source should be a non-empty string
            when 'source'
              source_option_check(descriptor_validator, descriptor, form_key, value)
            when 'datalist'
              datalist_check(descriptor_validator, descriptor, form_key, value)
          end
        end
      end

      # method to lint validate options external_hash attribute
      def self.hash_option_check(descriptor_validator, descriptor, form_key, value)
        #6
        if value.is_a?(Array)
          descriptor_validator.add_error('descriptors.invalid_option_enumerator', id: descriptor.id, key_type:
            form_key, value_type: 'list')
        elsif value.values.any? &:nil?
          #7 if any hash values are nil put out a warning
          descriptor_validator.add_warning('descriptors.missing_options_value', id: descriptor.id, options_attr:
            form_key)
        end
      end

      # method to lint validate options href attribute
      def self.href_option_check(descriptor_validator, descriptor, form_key, value)
        #8a. check for #' char, indicating a local resource#option-id
        if value.include?('#')
          descriptor_validator.add_warning('descriptors.invalid_options_ref', id: descriptor.id, options_attr:
            form_key, ref: value) unless value.split('#').size == 2

          #8b see if the LHS is an id in this file
          unless valid_descriptor?(value.split('#').first, descriptor_validator)
            descriptor_validator.add_error('descriptors.option_reference_not_found', id: descriptor.id,
              options_attr: form_key, ref: value, type: 'descriptor')
          end

          #8c see if the RHS is an option id extant in this file
          unless valid_options_id?(descriptor_validator, value.split('#').last)
            descriptor_validator.add_error('descriptors.option_reference_not_found', id: descriptor.id,
              options_attr: form_key, ref: value, type: 'option id')
          end
        else
          descriptor_validator.add_error('descriptors.invalid_options_protocol', id: descriptor.id, options_attr:
            form_key, uri: value) unless valid_protocol_type(value)
        end
      end

      # @return [Hash] the options for a descriptor
      def self.raw_options(descriptor)
        descriptor.descriptor_document[Crichton::Descriptor::Detail::OPTIONS]
      end

      # external_hash and external_list should point to a valid web protocol
      def self.external_option_check(descriptor_validator, descriptor, form_key, value)
        #9 check for valid url
        unless valid_protocol_type(value)
          descriptor_validator.add_error('descriptors.invalid_option_protocol', id: descriptor.id, options_attr:
            form_key, uri: value)
        end

        #10 test to see if value_attribute_name exists, if not, put out error
        descriptor_validator.add_error('descriptors.missing_options_key', id: descriptor.id, options_attr:
          form_key) unless raw_options(descriptor).has_key?('value_attribute_name')
      end

      # LHS of an href must point to a resource descriptor in document
      def self.valid_descriptor?(descriptor, descriptor_validator)
        descriptor_validator.resource_descriptor.descriptors.any? { |desc| desc.id.downcase == descriptor.downcase }
      end

      # the RHS of an href must be associated with an option with an id
      def self.valid_options_id?(descriptor_validator, option_id)
        find_matching_option_id(descriptor_validator.resource_descriptor.descriptors, option_id, false)
      end

      # recursive method to find a matching option with an id to to RHS of an option href attribute
      def self.find_matching_option_id(descriptors, option_id, found)
        descriptors.each do |descriptor|
          found = option_id_match?(raw_options(descriptor), option_id)
          break if found
          if descriptor.descriptors
            found = find_matching_option_id(descriptor.descriptors, option_id, found)
            break if found
          end
        end
        found
      end

      # low level option id match
      def self.option_id_match?(options, option_id)
        options && options.has_key?(:id.to_s) && options[:id.to_s] == option_id
      end

      # only http protocol is currently valid
      def self.valid_protocol_type(value)
        value && Crichton::Descriptor::Resource::PROTOCOL_TYPES.include?(value[/\Ahttp/])
      end

      def self.source_option_check(descriptor_validator, descriptor, form_key, value)
        if value
          descriptor_validator.add_error('descriptors.invalid_option_source_type', id: descriptor.id,
            options_attr: form_key) unless value.is_a?(String)
        else
          descriptor_validator.add_error('descriptors.missing_options_value', id: descriptor.id, options_attr: form_key)
        end
      end

      # check if an option datalist attribute points to a valid datalist item in the resource descriptor document
      def self.datalist_check(descriptor_validator, descriptor, form_key, value)
        if value
          unless descriptor_validator.resource_descriptor.datalists.keys.include?(value)
            descriptor_validator.add_error('descriptors.invalid_option_datalist', id: descriptor.id,
               options_attr: form_key, datalist: value)
          end
        else
          descriptor_validator.add_error('descriptors.missing_option_datalist_value', id: descriptor.id,
             options_attr: form_key)
        end
      end
    end
  end
end
