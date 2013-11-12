require 'crichton/descriptor/dereferencer'
require 'crichton/external_document_cache'
require 'crichton/external_document_store'

module Crichton
  ##
  # Manages descriptor documents and registers the descriptors
  class Registry
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
      register(resource_descriptor)
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register multiple descriptor documents without needing a second stage call.
    #
    # @param [Hash, String] resource_descriptors The hashified resource descriptor documents or filenames of YAML
    # resource descriptor documents.
    def register_multiple(resource_descriptors)
      resource_descriptors.each { |resource_descriptor| register(resource_descriptor) }
    end

    ##
    # Lists the registered resource descriptors that had local links dereferenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def descriptor_registry
      @descriptor_registry ||= begin
        (registry ||= {}).tap do |registry|
          dereference_queue.each do |d|
            d.dereference_hash_descriptor(ids_registry, external_descriptor_documents).tap do |hash|
              add_hash_descriptor_to_resources_list(hash).tap do |descriptor|
                add_to_registry(descriptor, registry)
              end
            end
          end
        end
      end
    end

    def datalist_registry
      @datalist_registry ||= begin
        if descriptor_registry
          (registry ||= {}).tap do |registry|
            resources_list.each { |resource| register_datalist(registry, resource) }
          end
        end
      end
    end

    ##
    # Lists the registered resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_descriptor_registry
      @raw_descriptor_registry ||= begin
        (registry ||= {}).tap do |registry|
          resources_list.each do |resource|
            resource.descriptors.each { |descriptor| add_to_registry(descriptor, registry) }
          end
        end
      end
    end
    ##

    # Lists the registered toplevel resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_profile_registry
      @raw_profile_registry ||= begin
        (registry ||= {}).tap do |registry|
          resources_list.each { |descriptor| add_to_registry(descriptor, registry) }
        end
      end
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
      add_hash_descriptor_to_dereferencing_queue(hash_descriptor)
      add_hash_descriptor_to_resources_list(hash_descriptor)
    end


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

    def add_hash_descriptor_to_dereferencing_queue(hash_descriptor)
      Crichton::Descriptor::Dereferencer.new(hash_descriptor, build_options_registry).tap do |dereferencer|
        dereference_queue << dereferencer
      end
    end

    def add_hash_descriptor_to_resources_list(hash_descriptor)
      Crichton::Descriptor::Resource.new(hash_descriptor).tap do |resource|
        resources_list << resource
      end
    end

    OPTIONS_STRING = 'options'
    def build_options_registry
      lambda do |descriptor_name_prefix, hash|
        if hash.include?(OPTIONS_STRING) && hash[OPTIONS_STRING].include?('id')
          options_registry["#{descriptor_name_prefix}\##{hash[OPTIONS_STRING]['id']}"] = hash[OPTIONS_STRING]
        end
      end
    end

    def dereference_queue
      @dereference_queue ||= []
    end

    def resources_list
      @resources_list ||= []
    end

    def add_to_registry(descriptor, registry)
      if registry[descriptor.id]
        raise ArgumentError, "Descriptor for #{descriptor.id} is already registered."
      end
      registry[descriptor.id] = descriptor
    end

    def ids_registry
      @ids_registry ||= begin
        (ids_registry ||= {}).tap do |ids_registry|
          dereference_queue.each { |dereferencer| build_ids_registry(ids_registry, dereferencer.collect_descriptor_ids)}
        end
      end
    end

    def build_ids_registry(ids, other)
      intersect = ids.reject { |k,v| !other.include? k }
      if intersect.empty?
        ids.merge!(other)
      else
        raise DescriptorAlreadyRegisteredError, "Descriptor for #{intersect.keys.join(" ")} is already registered."
      end
    end

    def register_datalist(registry, resource_descriptor)
      if datalists = resource_descriptor.descriptor_document['datalists']
        datalists.each { |k, v| registry["#{resource_descriptor.name}\##{k}"] = v }
      end
    end

  end
end
