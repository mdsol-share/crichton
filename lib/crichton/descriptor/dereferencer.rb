require 'addressable/uri'

module Crichton
  module Descriptor
    class Dereferencer

      def initialize(hash_descriptor, function)
        @hash_descriptor = hash_descriptor
        @function = function
        @logger = Crichton.logger
      end

      def dereference_hash_descriptor(ids_registry, external_descriptor_documents)
        build_dereferenced_hash_descriptor(ids_registry, @hash_descriptor['links']['self'], @hash_descriptor, external_descriptor_documents)
      end

      # This method calls the recursive method
      def collect_descriptor_ids
        descriptor_document_id = @hash_descriptor['id']
        descriptors = @hash_descriptor['descriptors']
        (ids_registry ||= {}).tap do |ids_registry|
          descriptors.each do |k, v|
            build_descriptor_hashes_by_id(k, descriptor_document_id, nil, v, ids_registry)
          end
        end
      end

      private
      # Recursive descent
      def build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, id, hash, ids_registry)
        @function.call(descriptor_name_prefix, hash)
        descriptor_name = "#{descriptor_name_prefix}\##{id}"
        if id && ids_registry.include?(descriptor_name)
          raise Crichton::DescriptorAlreadyRegisteredError, "Descriptor name #{descriptor_name} already in ids_registry!"
        end
        # Add descriptor to the IDs hash
        ids_registry["#{descriptor_name_prefix}\##{id}"] = hash unless id.nil?

        # Descend
        unless hash['descriptors'].nil?
          hash['descriptors'].each do |child_id, descriptor|
            build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, child_id, descriptor, ids_registry)
          end
        end
      end

      def external_document_cache
        @external_document_cache ||= Crichton::ExternalDocumentCache.new
      end

      def external_document_store
        @external_document_store ||= Crichton::ExternalDocumentStore.new
      end

      def load_external_profile(link, ids_registry, external_descriptor_documents)
        # find and get profile
        unless external_descriptor_documents.include?(link)
          begin
            external_descriptor_documents[link] = external_document_store.get(link) || external_document_cache.get(link)
          rescue => e
            error_message = "Link #{link} that was referenced in profile had an error: #{e.inspect}\n#{e.backtrace}"
            @logger.warn error_message
            raise(Crichton::ExternalProfileLoadError, error_message)
          end
        end
        # parse profile to hash
        profile = Crichton::ALPS::Deserialization.new(external_descriptor_documents[link])
        ext_profile_hash = profile.to_hash
        # add profile to id registry
        uri = URI.parse(link)
        uri.fragment = nil
        descriptor_root = uri.to_s
        descriptors = ext_profile_hash['descriptors']
        descriptors && descriptors.each do |k,v|
          build_descriptor_hashes_by_id(k, descriptor_root, nil, v, ids_registry)
        end
      end

      def build_dereferenced_hash_descriptor(ids_registry, descriptor_name_prefix, hash, external_descriptor_documents)
        new_hash = {}
        hash.each do |k, v|
          if k == 'href'
            url = Addressable::URI.parse(v)
            # If the URL is absolute then it is an external URL. So we need to do a little more work.
            if url.absolute?
              # External link
              # Load external profile (if possible) and add it to the IDs registry
              load_external_profile(v, ids_registry, external_descriptor_documents)
              # In case of an external link, the link 'as is' is taken as the key.
              v_with_prefix = v
            elsif url.fragment
              # Semi-local (other descriptor file but still local) link with a # fragment in it
              v_with_prefix = v
            else
              # Local (within descriptor file) - use the link as a fragment and add the current name as prefix
              v_with_prefix = "#{descriptor_name_prefix}\##{v}"
            end
            # Check if the link is in the registry - and if it is then merge it.
            if ids_registry.include? v_with_prefix
              unless new_hash.include?('dhref')
                new_hash['dhref'] = v
              end
              new_hash.deep_merge!(ids_registry[v_with_prefix].deep_dup)
            else
              new_hash[k] = v
            end
          elsif v.is_a? Hash
              der_ded = build_dereferenced_hash_descriptor(ids_registry, descriptor_name_prefix, v, external_descriptor_documents)
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

    end
  end
end
