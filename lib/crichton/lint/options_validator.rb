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
        (options.keys & %w(href list hash external)).size > 1
      end

      # class that dispatches for a variety of lint validation checks
      def self.option_rule_check(descriptor_validator, descriptor)
        # various rules depending upon the different types of options
        raw_options(descriptor).each do |form_key, value|
          #1-3 missing value for an option
          if %w(id href list hash external).include?(form_key)
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

            when 'external'
              external_option_check(descriptor_validator, descriptor, form_key, value) if value
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
        #9 check if value is hash
        (descriptor_validator.add_error('descriptors.invalid_option_enumerator', id: descriptor.id, key_type:
            form_key, value_type: value.class) && return) unless value.is_a?(Hash)

        source_option_check(descriptor_validator, descriptor, form_key, value)
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
        if source = value['source']
          descriptor_validator.add_error('descriptors.invalid_option_source_type', id: descriptor.id,
            options_attr: form_key) unless source.is_a?(String)

          if source.include?('://')
            descriptor_validator.add_error('descriptors.invalid_option_protocol', id: descriptor.id, options_attr:
              form_key, uri: value) unless valid_protocol_type(source)

            descriptor_validator.add_error('descriptors.missing_options_key', id: descriptor.id, options_attr:
              form_key, child_name: 'target') unless value.has_key?('target')

            descriptor_validator.add_error('descriptors.missing_options_key', id: descriptor.id, options_attr:
                form_key, child_name: 'prompt') unless value.has_key?('prompt')

            hash_option_check(descriptor_validator, descriptor, form_key, value)
          end
        end
      end
    end
  end
end
