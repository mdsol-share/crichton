module Crichton
  module Lint
    # class to check embed type descriptor options
    class EmbedValidator
      ##
      # standard lint validation method
      #
      # @param [Crichton::Lint::DescriptorsValidator] descriptor_validator  option validator object
      # @param [Crichton::Descriptor::Detail] descriptor current descriptor object
      def self.validate(descriptor_validator, descriptor)
        return unless descriptor.embed

        unless Crichton::Descriptor::Detail::EMBED_VALUES.include?(descriptor.embed)
          descriptor_validator.add_error('descriptors.invalid_embed_attribute', id: descriptor.id, embed_attr:
            descriptor.embed)
        end
      end
    end
  end
end
