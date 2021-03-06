require 'crichton/descriptor/dealiaser'
require 'crichton/descriptor/descriptor_element'
require 'crichton/descriptor/descriptor_keywords'

module Crichton
  module Descriptor
    ##
    # Represents descriptor document as resource. Resource document can be in different forms:
    # raw document, de-aliased document, dereferenced document.
    # De-references itself.
    class ResourceDereferencer
      KEYWORDS = [ID, DOC, LINKS, TAG, EXTENSIONS]

      attr_reader :resource_id
      attr_reader :resource_document
      attr_reader :dealiased_document
      attr_reader :raw_profile_document

      ##
      # Constructor. Represents entire resource descriptor document.
      #
      # @param [Hash] document Resource descriptor document.
      def initialize(document)
        @resource_document = document
        @dealiased_document = Dealiaser.dealias(document)
        @raw_profile_document = dealiased_document.select { |k, _| KEYWORDS.include?(k) }
        @resource_id = document[ID]
      end

      ##
      # All available descriptor elements in resource descriptor document
      #
      # @return [Hash] Hash of descriptor elements keyed by ResourceId#DescriptorId key.
      def resource_descriptors
        @registered_descriptors ||= {}.tap do |hash|
          register(raw_profile_document) { |h| hash.deep_merge!(h) }
        end
      end

      ##
      # Returns dealiased, dereferenced resource descriptor document.
      #
      # @return [Hash] Dereferenced resource descriptor document.
      def dereference(registry)
        @dereferenced_document ||= dealiased_document.deep_dup.tap do |acc|
          (acc[TAG] || {}).keys.each do |tag|
            registry["#{resource_id}\##{tag}"] ? acc[TAG][tag] = registry["#{resource_id}\##{tag}"] : {}
          end
        end
      end

      private
      def register(hash, &block)
        descriptors(hash).each do |tag, obj|
          key = "#{resource_id}\##{tag}"
          yield({ key => DescriptorElement.new(resource_id, tag, obj) }, register(obj, &block)) if obj.is_a?(Hash)
        end
      end

      def descriptors(hash)
        hash[TAG] && hash[TAG].is_a?(Hash) ? hash[TAG].merge(hash[EXTENSIONS] || {}) : {}
      end
    end
  end
end
