require 'crichton/helpers'

module Crichton
  module Descriptor
    ##
    # Represents descriptor. Responsible for self-dereferencing.
    class DescriptorElement
      include Crichton::Helpers::ConfigHelper
      include Crichton::Helpers::DescriptorKeywords

      attr_reader :descriptor_id
      attr_reader :descriptor_document
      attr_reader :document_id

      ##
      # Constructor
      #
      # @param [String] document_id The Id of resource descriptor document.
      # @param [String] element_id The Id of descriptor (or its name).
      # @param [Hash] The section of the descriptor document representing this instance.
      def initialize(document_id, element_id, descriptor_document)
        @descriptor_document = descriptor_document && descriptor_document.dup || {}
        @descriptor_id = element_id || @descriptor_document[ID]
        @document_id = document_id
      end

      ##
      # Options element of descriptor, used to reference a particular list and include its values in another values entry.
      #
      # @return [Hash] The section of the descriptor element representing options.
      def descriptor_options
        @descriptor_options ||= descriptors.inject(map_options(descriptor_document)) do |acc, hash|
          hash.is_a?(Hash) ? acc.merge!(map_options(hash)) : {}
        end
      end

      ##
      # Dereferences descriptor element.
      #
      # @param [Hash] registry Hash of all registered non-dereferenced descriptors found in all descriptor documents.
      # @param [Hash] dereferenced_hash Hash of all registered dereferenced descriptors.
      def dereference(registry, dereferenced_hash, &block)
        deref_descriptors = resolve_descriptors(descriptors, registry, dereferenced_hash)
        deref_href = uri ? resolve_href(uri, registry, dereferenced_hash) : {}
        deref = resolve_options(registry.options_registry, deref_href.deep_merge(deref_descriptors))
        yield(deref)
      end

      private
      def descriptors
        (descriptors = self.descriptor_document[TAG]) ? descriptors : {}
      end

      def map_options(hash)
        ((data = hash[OPTIONS]) && (id = hash[OPTIONS][ID])) ? { registry_key(id) => data } : {}
      end

      def resolve_descriptors(descriptors, registry, dereferenced_hash)
        if descriptors.is_a?(Hash)
          descriptors.inject({}) { |acc, (k,v)| acc.merge!({ k => dereferenced_hash[registry_key(k)].merge(v) }) }
        else
          descriptors.inject({}) do |acc, hash|
            key = registry_key(hash[HREF])
            if v = dereferenced_hash[key]
              acc.merge!({ hash[HREF] => extensions_dereference(registry, dereferenced_hash, hash, v) })
            else
              raw_registry_lookup(key, registry, dereferenced_hash) do |result|
                acc.merge!({ hash[HREF] => extensions_dereference(registry, dereferenced_hash, hash, result) })
              end
            end
          end
        end
      end

      def uri(href = self.descriptor_document[HREF])
        Addressable::URI.parse(href)
      end

      def registry_key(key)
        "#{document_id}\##{key}"
      end

      def extensions_dereference(registry, dereferenced_hash, original, dereferenced)
        dereferenced.deep_merge(original.reject{|k,_| k == HREF}).tap do |acc|
          if key = original[EXT]
            raw_registry_lookup(registry_key(key), registry, dereferenced_hash) do |h|
              acc.merge!(h).reject!{|k,_| k == EXT }
            end
          end
        end
      end

      def raw_registry_lookup(key, registry, dereferenced_hash, &block)
        descriptor_element = registry.raw_descriptors[key]
        descriptor_element ? descriptor_element.dereference(registry, dereferenced_hash, &block) : {}
      end

      def resolve_href(uri, registry, dereferenced_hash)
        func = (uri.absolute? ? external_dereference : local_dereference)
        func.(uri, registry, dereferenced_hash)
      end

      def external_dereference
        lambda do |uri, registry, dereferenced_hash|
          unless dereferenced_hash[uri.to_s]
            dereferenced_hash[uri.to_s] = external_alps_profile_dereference(uri, registry, dereferenced_hash)
          end
          dereferenced_hash[uri.to_s]
        end
      end

      def external_alps_profile_dereference(uri, registry, dereferenced_hash)
        {}.tap do |acc|
          hash = registry.get_external_deserialized_profile(uri)
          (descriptors = hash[TAG]) && descriptors.each do |k,v|
            descriptor_element = DescriptorElement.new(uri, k, v)
            descriptor_element.dereference(registry, dereferenced_hash) { |h| acc.merge!({ k => h}) }
          end
        end
      end

      def local_dereference
        lambda do |uri, registry, dereferenced_hash|
          key = (uri.fragment ? uri.to_s : registry_key(uri.to_s))
          if dereferenced_hash[key]
            (result = dereferenced_hash[key][TAG]) ? result : {}
          else
            {}.tap { |acc| raw_registry_lookup(key, registry, dereferenced_hash) { |h| acc.merge!(h[TAG]) } }
          end
        end
      end

      def resolve_options(registry, hash)
        doc = dereference_options(registry, self.descriptor_document.deep_dup)
        deref_hash = hash.inject({}) do |acc, (k,v)|
          acc.merge!({ k => dereference_options(registry, v) })
        end
        deref_hash.any? ? doc.deep_merge({ TAG => deref_hash }) : doc
      end

      def dereference_options(registry, hash)
        if ((options = hash[OPTIONS]) && (href = options[HREF]))
          uri = uri(href)
          key = uri.fragment ? uri.to_s : registry_key(uri.to_s)
          hash.merge({ OPTIONS => registry[key] })
        else
          hash
        end
      end
    end
  end
end
