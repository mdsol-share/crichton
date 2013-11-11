require 'crichton/descriptor/dereferencer'
require 'crichton/external_document_cache'
require 'crichton/external_document_store'

module Crichton
  ##
  # Manages descriptor documents and registers the descriptors
  class Registry
    def initialize(options = {})
      @logger = Crichton.logger
      register_multiple(Crichton.descriptor_filenames) unless options[:automatic_load] == false
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register a single descriptor document without needing a second stage call.
    #
    # @param [Hash, String] resource_descriptor The hashified resource descriptor document or filename of a YAML
    # resource descriptor document.
    def register_single(resource_descriptor)
      resource = register(resource_descriptor)
      dereference_queued_descriptor_hashes_and_build_registry
      resource
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register multiple descriptor documents without needing a second stage call.
    #
    # @param [Hash, String] resource_descriptors The hashified resource descriptor documents or filenames of YAML
    # resource descriptor documents.
    def register_multiple(resource_descriptors)
      resource_descriptors.each { |resource_descriptor| register(resource_descriptor) }
      dereference_queued_descriptor_hashes_and_build_registry
    end

    ##
    # Lists the registered resource descriptors that had local links dereferenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def descriptor_registry
      @descriptor_registry ||= {}
    end

    def datalist_registry
      @datalist_registry ||= {}
    end

    ##
    # Lists the registered resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_descriptor_registry
      @raw_descriptor_registry ||= {}
    end
    ##

    # Lists the registered toplevel resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_profile_registry
      @raw_profile_registry ||= {}
    end

    def options_registry
      @options_registry ||= {}
    end

    #TODO: Add
    # profile_registry and raw_profile_registry

    ##
    # Whether any resource descriptors have been registered or not.
    #
    # @return [Boolean] true, if any resource descriptors are registered.
    def registrations?
      descriptor_registry.any?
    end

    ##
    # external_descriptor_documents
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

    def ids_registry
      @ids_registry ||= {}
    end

    def dereference_queue
      @dereference_queue ||= []
    end

    ##
    # Registers a resource descriptor document by name and version in the raw registry.
    # This is intended to be used by build_registry or register_single but in tests could be useful to be called
    # directly. After all descriptor documents have been registered with this method, call
    # dereference_queued_descriptor_hashes_and_build_registry to do the dereferencing in the next step.
    #
    #
    # @param [Hash, String] resource_descriptor The hashified resource descriptor document or filename of a YAML
    # resource descriptor document.
    def register(resource_descriptor)
      hash_descriptor = load_resource_descriptor(resource_descriptor)

      # Add the non-dereferenced descriptor document -
      # the de-referencing will need to wait until all IDs are collected.
      add_resource_descriptor_to_dereferencing_queue(hash_descriptor)

      resource_descriptor = add_resource_descriptor_to_registry(hash_descriptor, raw_descriptor_registry)
      add_resource_descriptor_to_raw_profile_registry(resource_descriptor)
      resource_descriptor
    end

    ##
    # Finishes registration by building de-referenced descriptors. The de-referencing only makes sense once all
    # local descriptor documents have been loaded.
    def dereference_queued_descriptor_hashes_and_build_registry
      dereference_queue.each do |dereferencer|
        # Build hash with resolved local links
        dereferencer.dereference_hash_descriptor(ids_registry, external_descriptor_documents).tap do |hash|
          add_resource_descriptor_to_registry(hash, descriptor_registry)
        end
      end
    end

    def add_resource_descriptor_to_dereferencing_queue(hash_descriptor)
      dereferencer = Crichton::Descriptor::Dereferencer.new(hash_descriptor, add_values_to_options_registry)
      ids_registry.merge!(dereferencer.collect_descriptor_ids)
      dereference_queue << dereferencer
    end

    def add_resource_descriptor_to_raw_profile_registry(resource_descriptor)
      if raw_profile_registry[resource_descriptor.id]
        raise ArgumentError, "Resource descriptor profile for #{resource_descriptor.id} is already registered."
      end
      raw_profile_registry[resource_descriptor.id] = resource_descriptor
    end

    def add_resource_descriptor_to_registry(hash_descriptor, registry)
      Crichton::Descriptor::Resource.new(hash_descriptor).tap do |resource_descriptor|
        register_datalist(resource_descriptor)
        resource_descriptor.descriptors.each do |descriptor|
          if registry[descriptor.id]
            raise Crichton::DescriptorAlreadyRegisteredError,
              "Resource descriptor for #{descriptor.id} is already registered."
          end
          registry[descriptor.id] = descriptor
        end
      end
    end

    def register_datalist(resource_descriptor)
      if datalists = resource_descriptor.descriptor_document['datalists']
        datalists.each { |k, v| datalist_registry["#{resource_descriptor.name}\##{k}"] = v }
      end
    end

    OPTIONS_STRING = 'options'
    def add_values_to_options_registry
      lambda do |descriptor_name_prefix, hash|
        if hash.include?(OPTIONS_STRING) && hash[OPTIONS_STRING].include?('id')
          options_registry["#{descriptor_name_prefix}\##{hash[OPTIONS_STRING]['id']}"] = hash[OPTIONS_STRING]
        end
      end
    end

  end
end
