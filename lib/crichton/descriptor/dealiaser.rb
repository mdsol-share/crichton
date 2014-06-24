require 'crichton/helpers'
require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor
    ##
    # Manages dealiasing human-friendly tags in resource descriptor documents
    # to their base ALPS-related tags underlying the resource descriptor functionality.
    class Dealiaser
      KEYWORDS = TYPES + [DATA, TAG, PARAMETERS, RESOURCES]

      ##
      # Recursively dealiases human-friendly tags.
      # @param [Hash] hash Resource descriptor document hash.
      # @return [Hash] The de-aliased descriptor document.
      def self.dealias(hash)
        hash.each_with_object({}) do |(tag, content), h|
          value = (content.is_a?(Hash) ? dealias(content) : content)
          normalize(tag, value, h)
        end
      end

      private
      # Replaces semantics, safe, unsafe, idempotent, descriptors, parameters and resources keywords
      # with descriptors keyword.
      def self.normalize(key, value, hash)
        KEYWORDS.include?(key) ? inject(hash, transform(key), value) : hash.merge!(post_process(key, value))
      end

      def self.post_process(tag, content)
        if tag.include?("_#{PROTOCOL}")
          type = tag.split('_').first
          { PROTOCOL.pluralize => { type => content } }
        else
          { tag => content }
        end
      end

      def self.inject(hash, func, value)
        hash.include?(TAG) ? hash[TAG].merge!(func.(value)) : hash[TAG] = func.(value)
      end

      # Special keyword parameters. Defines semantics descriptors as url parameters.
      # Such descriptor elements will have extra information to indicate that: scope: url.
      # Otherwise, as per ALPS, we add type attribute to descriptor element, e.g. type: semantic
      def self.transform(key)
        key == PARAMETERS ? add_scope({ 'scope' => 'url' }) : add_type({ TYPE => map_key(key) })
      end

      def self.add_scope(hash)
        ->(obj) { obj.is_a?(Array) ? obj.each { |h| h.deep_merge!(hash) } : obj.each { |_, v| v.deep_merge!(hash) } }
      end

      def self.add_type(hash)
        lambda do |obj|
          if obj.is_a?(Hash)
            obj.each { |_, v| v.deep_merge!(hash) unless v[TYPE].present? }
          else
            obj
          end
        end
      end

      # Special case semantics. Used as singular in ALPS.
      def self.map_key(key)
        TYPES.include?(key) ? key.singularize : SEMANTIC
      end
    end
  end
end
