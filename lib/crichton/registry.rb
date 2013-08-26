require 'crichton/descriptor_dereferencer'

module Crichton
  ##
  # Manages descriptor documents and registers the descriptors
  class Registry
    def initialize(args = {})
      @logger = Crichton.logger
      build_registry unless args[:automatic_load] == false
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
      @registry ||= {}
    end

    ##
    # Lists the registered resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_descriptor_registry
      @raw_descriptor_registry ||= {}
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
      hash_descriptor = case resource_descriptor
        when String
          raise ArgumentError, "Filename #{resource_descriptor} is not valid." unless File.exists?(resource_descriptor)
          YAML.load_file(resource_descriptor)
        when Hash
          resource_descriptor
        else
          raise ArgumentError, "Document #{resource_descriptor} must be a String or a Hash."
        end

      # Collect the hash fragments for dereferencing keyed by the ID (which is a link to a descriptor element)
      collect_descriptor_ids(hash_descriptor)

      # Add the non-dereferenced descriptor document -
      # the de-referencing will need to wait until all IDs are collected.
      add_resource_descriptor_to_dereferencing_queue(hash_descriptor)
      add_resource_descriptor_to_registry(hash_descriptor, @raw_descriptor_registry ||= {})
    end

    ##
    # Finishes registration by building de-referenced descriptors. The de-referencing only makes sense once all
    # local descriptor documents have been loaded.
    def dereference_queued_descriptor_hashes_and_build_registry
      @dereference_queue.each do |hash_descriptor|
        # Build hash with resolved local links
        dereferencer = Crichton::Descriptor::Dereferencer.new(@ids_registry) {|v| load_external_profile(v)}
        dereferenced_hash_descriptor = dereferencer.build_dereferenced_hash_descriptor(
          hash_descriptor['links']['self'], hash_descriptor)
        add_resource_descriptor_to_registry(dereferenced_hash_descriptor, (@registry ||= {}))
      end
      @dereference_queue = nil
    end


    # Loads all descriptor documents from the descriptor directory location and processes them
    #
    # De-references documents after loading all available documents
    def build_registry
      if File.exists?(location = Crichton.descriptor_location)
        Dir.glob(File.join(location, '*.{yml,yaml}')).each do |f|
          register(YAML.load_file(f))
        end
        # The above register step works on a per-file basis. If a early file references a later file, it won't be
        # able to dereference the data. So in order to handle this, the de-referencing needs to be done in a later
        # step. Not elegant, but should get the job done.
        dereference_queued_descriptor_hashes_and_build_registry
      else
        raise "No resource descriptor directory exists. Default is #{Crichton.descriptor_location}."
      end
    end


    def add_resource_descriptor_to_dereferencing_queue(hash_descriptor)
      (@dereference_queue ||= []) << hash_descriptor
    end

    def add_resource_descriptor_to_registry(hash_descriptor, registry)
      Crichton::Descriptor::Resource.new(hash_descriptor).tap do |resource_descriptor|
        resource_descriptor.descriptors.each do |descriptor|
          if registry[descriptor.id]
            raise ArgumentError, "Resource descriptor for #{descriptor.id} is already registered."
          end
          registry[descriptor.id] = descriptor
        end
      end
    end

    # This method calls the recursive method
    def collect_descriptor_ids(hash_descriptor)
      descriptor_document_id = hash_descriptor['id']
      descriptors = hash_descriptor['descriptors']
      descriptors.each do |k, v|
        build_descriptor_hashes_by_id(k, descriptor_document_id, nil, v)
      end
    end

    # Recursive descent
    def build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, id, hash)
      @ids_registry ||= {}
      if id && @ids_registry.include?(id)
        raise "Descriptor name #{id} already in ids_registry!"
      end
      # Add descriptor to the IDs hash
      @ids_registry["#{descriptor_name_prefix}\##{id}"] = hash unless id.nil?

      # Descend
      unless hash['descriptors'].nil?
        hash['descriptors'].each do |child_id, descriptor|
          build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, child_id, descriptor)
        end
      end
    end


    def load_external_profile(link)
      # find and get profile
      unless (@external_descriptor_documents ||= {}).include?(link)
        begin
          @external_descriptor_documents[link] = Net::HTTP.get(URI(link))
        rescue => e
          error_message = "Link #{link} that was referenced in profile had an error: #{e.inspect}"
          @logger.warn error_message
          raise(Crichton::ExternalProfileLoadError, error_message)
        end
      end
      # parse profile to hash
      profile = Crichton::ALPS::Deserialization.new(@external_descriptor_documents[link])
      ext_profile_hash = profile.to_hash
      # add profile to id registry
      uri = URI.parse(link)
      uri.fragment = nil
      descriptor_root = uri.to_s
      descriptors = ext_profile_hash['descriptors']
      descriptors && descriptors.each do |k,v|
        build_descriptor_hashes_by_id(k, descriptor_root, nil, v)
      end
    end
  end
end
