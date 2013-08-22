module Crichton
  ##
  # Manages descriptor documents and registers the descriptors
  class Registry
    def initialize(automatic_load = true)
      @logger = Crichton.logger
      build_registry if automatic_load
    end

    ##
    # This is intended to be used in combination with automatic_load = false in the initializer.
    # It allows (particularly specs to) register a single descriptor document without needing a second stage call.
    def register_single(resource_descriptor)
      register(resource_descriptor)
      dereference_queued_descriptor_hashes_and_build_registry
    end

    ##
    # Registers a resource descriptor document by name and version.
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
      add_resource_descriptor_to_registry(hash_descriptor, @raw_registry ||= {})
    end

    def dereference_queued_descriptor_hashes_and_build_registry
      @dereference_queue.each do |hash_descriptor|
        # Build hash with resolved local links
        dereferenced_hash_descriptor = build_dereferenced_hash_descriptor(hash_descriptor['links']['self'],
          hash_descriptor)
        add_resource_descriptor_to_registry(dereferenced_hash_descriptor, (@registry ||= {}))
      end
      @dereference_queue = nil
    end

    ##
    # Lists the registered resource descriptors that had local links dereferenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def registry
      @registry ||= {}
    end

    ##
    # Lists the registered resource descriptors that do not have local links de-referenced.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def raw_registry
      @raw_registry ||= {}
    end

    ##
    # Whether any resource descriptors have been registered or not.
    #
    # @return [Boolean] true, if any resource descriptors are registered.
    def registrations?
      registry.any?
    end

    private

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
        raise "No resource descriptor directory exists. Default is #{descriptor_location}."
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

    def build_dereferenced_hash_descriptor(descriptor_name_prefix, hash)
      new_hash = {}
      hash.each do |k, v|
        if k == 'href'
          # If the URL starts with 'http' then it is an external URL. So we need to do a little more work.
          if v.start_with?('http')
            # External link
            # Load external profile (if possible) and add it to the IDs registry
            load_external_profile(v)
            # In case of an external link, the link 'as is' is taken as the key.
            v_with_prefix = v
          elsif v.include? '#'
            # Semi-local (other descriptor file but still local) link with a # fragment in it
            v_with_prefix = v
          else
            # Local (within descriptor file) - use the link as a fragment and add the current name as prefix
            v_with_prefix = "#{descriptor_name_prefix}\##{v}"
          end
          # Check if the link is in the registry - and if it is then merge it.
          if @ids_registry.include? v_with_prefix
            unless new_hash.include?('dhref')
              new_hash['dhref'] = v
            end
            new_hash.deep_merge!(@ids_registry[v_with_prefix].deep_dup)
          else
            new_hash[k] = v
          end
        elsif v.is_a? Hash
            der_ded = build_dereferenced_hash_descriptor(descriptor_name_prefix, v)
          if new_hash.include? k
            new_hash[k].deep_merge! der_ded
          else
            new_hash[k] = der_ded
          end
        else
          new_hash[k] = v
        end
      end
      new_hash
    end

    def load_external_profile(link)
      # find and get profile
      unless (@external_descriptor_documents ||= {}).include?(link)
        begin
          @external_descriptor_documents[link] = Net::HTTP.get(URI(link))
        rescue => e
          error_message = "Link #{link} that was referenced in profile had an error: #{e.inspect}"
          # FIXME: After the refactor, get logger working again.
          #logger.warn error_message
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
