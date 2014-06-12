require 'crichton/helpers'
require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor
    ##
    # Represents descriptor. Responsible for self-dereferencing.
    class DescriptorElement

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
        @descriptor_options ||= descriptors.each_with_object(map_options(descriptor_document)) do |descriptor, h|
          h.merge!(map_options(descriptor)) if descriptor.is_a?(Hash)
        end
      end

      ##
      # Dereferences descriptor element.
      #
      # @param [Hash] registry Hash of all registered non-dereferenced descriptors found in all descriptor documents.
      # @param [Hash] dereferenced_hash Hash of all registered dereferenced descriptors.
      def dereference(registry, dereferenced_hash, &block)
        deref_descriptors = descriptors.any? ? { TAG => resolve_descriptors(registry, dereferenced_hash) } : {}
        deref_href = uri ? resolve_href(registry, dereferenced_hash) : {}
        deref = deref_href.deep_merge(self.descriptor_document.deep_merge(deref_descriptors))
        full_dereferenced = resolve_options(registry.options_registry, deref)
        yield full_dereferenced if block_given?
        full_dereferenced
      end

      private
      def descriptors
        @descriptors ||= self.descriptor_document[TAG] || {}
      end

      def map_options(hash)
        ((data = hash[OPTIONS]) && (id = hash[OPTIONS][ID])) ? { registry_key(id) => data } : {}
      end

      def resolve_descriptors(registry, dereferenced_hash)
        if descriptors.is_a?(Hash)
          resolve_hash_descriptors(registry, dereferenced_hash)
        else
          resolve_array_descriptors(registry, dereferenced_hash)
        end
      end

      def resolve_hash_descriptors(registry, dereferenced_hash)
        descriptors.inject({}) do |acc, (tag, content)|
          acc.merge!({ tag => dereferenced_hash[registry_key(tag)].merge(content) })
        end
      end

      def resolve_array_descriptors(registry, dereferenced_hash)
        descriptors.inject({}) do |acc, hash|
          key = registry_key(hash[HREF])
          if h = dereferenced_hash[key]
            acc.merge!({ hash[HREF] => extensions_dereference(registry, dereferenced_hash, hash, h) })
          else
            raw_registry_lookup(key, registry, dereferenced_hash) do |result|
              acc.merge!({ hash[HREF] => extensions_dereference(registry, dereferenced_hash, hash, result) })
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
        dereferenced.deep_merge(original.reject{ |tag, _| tag == HREF}).tap do |acc|
          if key = original[EXT]
            raw_registry_lookup(registry_key(key), registry, dereferenced_hash) do |h|
              acc.merge!(h).reject!{ |tag, _| tag == EXT }
            end
          end
        end
      end

      def raw_registry_lookup(key, registry, dereferenced_hash, &block)
        if descriptor_element = registry.raw_descriptors[key]
          descriptor_element.dereference(registry, dereferenced_hash, &block)
        else
          doc_id, name = key.split('#')
          raise(Crichton::DescriptorNotFoundError,
            "No descriptor element '#{name}' has been found in '#{doc_id}' descriptor document.")
        end
      end

      def resolve_href(registry, dereferenced_hash)
        func = (uri.absolute? ? external_dereference : local_dereference)
        func.(uri, registry, dereferenced_hash)
      end

      def external_dereference
        lambda do |uri, registry, dereferenced_hash|
          unless dereferenced_hash[uri.to_s]
            dereferenced_hash[uri.to_s] = registry.external_profile_dereference(uri.to_s)
          end
          dereferenced_hash[uri.to_s]
        end
      end

      def local_dereference
        lambda do |uri, registry, dereferenced_hash|
          key = uri.fragment ? uri.to_s : registry_key(uri.to_s)
          if dereferenced_hash[key]
            (result = dereferenced_hash[key]) ? result : {}
          else
            raw_registry_lookup(key, registry, dereferenced_hash) || {}
          end
        end
      end

      def resolve_options(registry, hash)
        (descriptors = hash[TAG]) && descriptors.each do |tag, content|
          deref_options = resolve_options(registry, content)
          descriptors[tag].merge!(deref_options)
        end
        dereference_options(registry, hash)
      end

      def dereference_options(registry, hash)
        if (options = hash[OPTIONS]) && (href = options[HREF])
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
