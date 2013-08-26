module Crichton
  module Descriptor
    class Dereferencer
      ##
      # ids_
      def initialize(ids_registry, &load_external_profile)
        @ids_registry = ids_registry
        @load_external_profile = load_external_profile
      end

      def build_dereferenced_hash_descriptor(descriptor_name_prefix, hash)
        new_hash = {}
        hash.each do |k, v|
          if k == 'href'
            # If the URL starts with 'http' then it is an external URL. So we need to do a little more work.
            if v.start_with?('http')
              # External link
              # Load external profile (if possible) and add it to the IDs registry
              @load_external_profile.call(v)
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

    end
  end
end
