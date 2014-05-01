require 'crichton/helpers'

module Crichton
  module Descriptor
    ##
    # De-aliases resource descriptor document. Converts from new format to the old one.
    class Dealiaser
      include Crichton::Helpers::ConfigHelper
      include Crichton::Helpers::DescriptorKeywords

      KEYWORDS = TYPES + [TAG, PARAMETERS, RESOURCES]

      ##
      # @param [Hash] resource_descriptor Resource descriptor document hash.
      # @return [Hash] The de-aliases descriptor document.
      def self.dealias(hash)
        {}.tap do |acc|
          hash.each do |k,v|
            value = (v.is_a?(Hash) ? dealias(v) : v)
            normalize(k, value, acc)
          end
        end
      end

      private
      ##
      # Replaces semantics, safe, unsafe, idempotent, descriptors, parameters and resources keywords
      # with descriptors keyword.
      def self.normalize(key, value, acc)
        KEYWORDS.include?(key) ? inject(acc, transform(key), value) : acc.merge!({ key => value })
      end

      def self.inject(acc, func, value)
        acc.include?(TAG) ? acc[TAG].merge!(func.(value)) : acc[TAG] = func.(value)
      end

      ##
      # Special keyword parameters. Defines semantics descriptors as url parameters.
      # Such descriptor elements will have extra information to indicate that: scope: url.
      # Otherwise, as per ALPS, we add type attribute to descriptor element, e.g. type: semantic
      def self.transform(key)
        key == PARAMETERS ? add_scope({ 'scope' => 'url' }) : add_type({ TYPE => map_key(key) })
      end

      def self.add_scope(hash)
        ->(value) { value.is_a?(Array) ? value.each { |h| h.deep_merge!(hash) } : value.each { |_,v| v.deep_merge!(hash) } }
      end

      def self.add_type(hash)
        ->(value) { value.is_a?(Hash) ?  value.each { |_,v| v.deep_merge!(hash) } : value }
      end

      ##
      # Special case semantics. Used as singular in ALPS.
      def self.map_key(key)
        TYPES.include?(key) ? key.singularize : SEMANTIC
      end
    end
  end
end
