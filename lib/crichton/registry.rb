require 'crichton/external_document_cache'
require 'crichton/external_document_store'
require 'crichton/alps/deserialization'
require 'crichton/descriptor/resource_dereferencer'
require 'crichton/descriptor/descriptor_keywords'

module Crichton
  ##
  # Manages descriptor documents and registers the descriptors
  class Registry
    include Crichton::Helpers::ConfigHelper

    def initialize(options = {})
      register_multiple(Crichton.descriptor_filenames) unless options[:automatic_load] == false
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register a single descriptor document without needing a second stage call.
    #
    # @param [Hash, String] resource_descriptor The hashified resource descriptor document or filename of a YAML
    # resource descriptor document.
    def register_single(resource_descriptor)
      register_multiple([resource_descriptor])
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register multiple descriptor documents without needing a second stage call.
    #
    # @param [Hash, String] resource_descriptors The hashified resource descriptor documents or filenames of YAML
    # resource descriptor documents.
    def register_multiple(resource_descriptors)
      @resources_registry = {}.tap do |hash|
        resource_descriptors.each do |file|
          document = load_resource_descriptor(file)
          resource = Crichton::Descriptor::ResourceDereferencer.new(document)
          hash[resource.resource_id] = resource
        end
      end
    end

    # Lists the registered resource descriptors that had local links dereferenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def descriptor_registry
      @descriptor_registry ||= {}.tap do |registry|
        resources_registry.values.each do |resource_dereferencer|
          hash = resource_dereferencer.dereference(dereferenced_descriptors)
          resource = Crichton::Descriptor::Resource.new(hash)
          resource.resources.each { |descriptor| registry[descriptor.id] = descriptor }
        end
      end
    end

    ##
    # Lists the registered resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_descriptor_registry
      @raw_descriptor_registry ||= {}.tap do |registry|
        resources_registry.values.each do |resource_dereferencer|
          resource = Crichton::Descriptor::Resource.new(resource_dereferencer.dealiased_document)
          resource.resources.each { |descriptor| registry[descriptor.id] = descriptor }
        end
      end
    end

    # Lists the registered toplevel resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_profile_registry
      @raw_profile_registry ||= {}.tap do |registry|
        resources_registry.each do |document_id, resource_dereferencer|
          registry[document_id] = Crichton::Descriptor::Resource.new(resource_dereferencer.dealiased_document)
        end
      end
    end

    #TODO: Add
    # profile_registry and raw_profile_registry

    # Lists the registered options descriptors found in all descriptors from all descriptor files.
    #
    # @return [Hash] The registered options descriptors, if any.
    def options_registry
      @options_registry ||= {}.tap do |hash|
        raw_descriptors.values.each { |descriptor_element| hash.merge!(descriptor_element.descriptor_options) }
      end
    end

    ##
    # Whether any resource descriptors have been registered or not.
    #
    # @return [Boolean] true, if any resource descriptors are registered.
    def registrations?
      descriptor_registry.any?
    end

    # Contains hash of all descriptors from all resource descriptor files. Links are not dereferenced.
    # Elements are keyed by 'document_id + descriptor_id' key.
    def raw_descriptors
      @raw_descriptors ||= resources_registry.values.each_with_object({}) do |resource_dereferencer, hash|
        hash.merge!(resource_dereferencer.resource_descriptors)
      end
    end

    # Contains hash of all descriptors from all resource descriptor files. Links are dereferenced.
    def dereferenced_descriptors
      @dereferenced_descriptors ||= raw_descriptors.each_with_object({}) do |(k, descriptor_element), hash|
        descriptor_element.dereference(self, hash) { |h| hash.deep_merge!({ k => h }) }
      end
    end

    def external_profile_dereference(uri)
      hash = get_external_deserialized_profile(uri)
      result = (hash[Crichton::Descriptor::TAG] || {}).each_with_object({}) do |(tag, content), dereferenced_hash|
        descriptor_element = Crichton::Descriptor::DescriptorElement.new(uri.to_s, tag, content)
        descriptor_element.dereference(self, dereferenced_hash) do |h|
          dereferenced_hash.deep_merge!({ uri.to_s => h })
        end
      end
      result[uri.to_s] || {}
    end

    def resources_registry
      @resources_registry ||= {}
    end

    def external_descriptor_documents
      @external_descriptor_documents ||= {}
    end

    private
    def load_resource_descriptor(resource_descriptor)
      hash_descriptor = case resource_descriptor
      when String
        raise ArgumentError, "Filename #{resource_descriptor} is not valid." unless File.exists?(resource_descriptor)
        YAML.load_file(resource_descriptor)
      when Hash
        resource_descriptor
      else
        raise ArgumentError, "Document #{resource_descriptor} must be a String or a Hash."
      end
    end

    def get_external_deserialized_profile(uri)
      unless external_descriptor_documents[uri]
        external_descriptor_documents[uri] = external_document_store.get(uri) || external_document_cache.get(uri)
      end
      Crichton::ALPS::Deserialization.new(external_descriptor_documents[uri]).to_hash
    end

    def external_document_store
      @external_document_store ||= Crichton::ExternalDocumentStore.new
    end

    def external_document_cache
      @external_document_cache ||= Crichton::ExternalDocumentCache.new
    end
  end
end
