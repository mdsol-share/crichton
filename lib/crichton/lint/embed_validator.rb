module Crichton
  module Lint
    class EmbedValidator
      def self.validate(descriptor_validator, descriptor)
        unless Crichton::Descriptor::Detail::EMBED_VALUES.include?(descriptor.embed)
          descriptor_validator.add_error('descriptors.invalid_embed_attribute', id: descriptor.id, embed_attr:
            descriptor.embed)
        end
      end
    end
  end
end
