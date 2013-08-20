require 'crichton/descriptor/http'
require 'crichton/descriptor/profile'
require 'crichton/descriptor/detail'
require 'crichton/descriptor/state'
require 'net/http'

module Crichton
  module Descriptor
    ##
    # Manages Resource Descriptor parsing and consumption for decorating service responses or interacting with
    # Hypermedia types.
    class Resource < Profile
      ##
      # Clears all registered resource descriptors
      def self.clear_registry
        @registry = nil
        @raw_registry = nil
        @ids_registry = nil
        @dereference_queue = nil
      end
      
      ##
      # Registers a resource descriptor document by name and version.
      #
      # @param [Hash, String] resource_descriptor The hashified resource descriptor document or filename of a YAML 
      # resource descriptor document.
      def self.register(resource_descriptor)
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
        add_resource_descriptor_to_registry(hash_descriptor, raw_registry)
      end

      def self.add_resource_descriptor_to_dereferencing_queue(hash_descriptor)
        (@dereference_queue ||= []) << hash_descriptor
      end

      def self.dereference_queued_descriptor_hashes_and_build_registry
        @dereference_queue.each do |hash_descriptor|
          # Build hash with resolved local links
          dereferenced_hash_descriptor = build_dereferenced_hash_descriptor(hash_descriptor['links']['self'],
            hash_descriptor)
          add_resource_descriptor_to_registry(dereferenced_hash_descriptor, registry)
        end
        @dereference_queue = nil
      end

      def self.add_resource_descriptor_to_registry(hash_descriptor, registry)
        new(hash_descriptor).tap do |resource_descriptor|
          resource_descriptor.descriptors.each do |descriptor|
            if registry[descriptor.id]
              raise ArgumentError, "Resource descriptor for #{descriptor.id} is already registered."
            end
            registry[descriptor.id] = descriptor
          end
        end
      end

      # This method calls the recursive method
      def self.collect_descriptor_ids(hash_descriptor)
        descriptor_document_self = hash_descriptor['links']['self']
        descriptors = hash_descriptor['descriptors']
        descriptors.each do |k, v|
          build_descriptor_hashes_by_id(k, descriptor_document_self, [k], nil, v)
        end
      end
      private_class_method :collect_descriptor_ids

      # Recursive descent
      def self.build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, pre_path, id, hash)
        cur_path = [pre_path, [id]].flatten.compact
        @ids_registry ||= {}
        if !id.nil? && @ids_registry.include?(id)
          raise "Descriptor name #{id} already in ids_registry!"
        end
        # Add descriptor to the IDs hash
        @ids_registry["#{descriptor_name_prefix}\##{cur_path.join('/')}"] = hash unless id.nil?

        # Descend
        unless hash['descriptors'].nil?
          hash['descriptors'].each do |child_id, descriptor|
            build_descriptor_hashes_by_id(descriptor_id, descriptor_name_prefix, cur_path, child_id, descriptor)
          end
        end
      end
      private_class_method :build_descriptor_hashes_by_id

      def self.build_dereferenced_hash_descriptor(descriptor_name_prefix, hash)
        new_hash = {}
        hash.each do |k, v|
          if k == 'href'
            # If the URL starts with 'http' then it is an external URL. So we need to do a little more work.
            # The alps.io links are 'primitives' - there isn't much of a point in de-referencing them.
            # TODO: Figure out if there is a better way of doing this than manually excluding that URL prefix.
            if v.start_with?('http') && !v.start_with?("http://alps.io")
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
      private_class_method :build_dereferenced_hash_descriptor

      def self.load_external_profile(link)
        # find and get profile
        begin
          profile_data = Net::HTTP.get(URI(link))
        rescue => e
          error_message = "Link #{link} that was referenced in profile had an error: #{e.inspect}"
          logger.warn error_message
          raise(Crichton::ExternalProfileLoadError, error_message)
        end
        # parse profile to hash
        profile = Crichton::ALPS::Deserialization(profile_data)
        ext_profile_hash = profile.to_hash
        # add profile to id registry
        uri = URI.parse(link)
        uri.fragment = nil
        descriptor_root = uri.to_s
        descriptors = ext_profile_hash['descriptors']
        descriptors.each do |k,v|
          build_descriptor_hashes_by_id(k, descriptor_root, [k], nil, v)
        end
      end

      ##
      # Lists the registered resource descriptors that had local links dereferenced.
      #
      # @return [Hash] The registered resource descriptors, if any.
      def self.registry
        @registry ||= {}
      end

      ##
      # Lists the registered resource descriptors that do not have local links de-referenced.
      #
      # @return [Hash] The registered resource descriptors, if any.
      def self.raw_registry
        @raw_registry ||= {}
      end

      ##
      # Whether any resource descriptors have been registered or not.
      #
      # @return [Boolean] true, if any resource descriptors are registered.
      def self.registrations?
        registry.any?
      end
  
      ##
      # Constructor
      #
      # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
      def initialize(descriptor_document)
        super(self, descriptor_document)
        verify_descriptor(descriptor_document)
      end
  
      # @!macro descriptor_reader
      descriptor_reader :version
      
      ##
      # Lists the protocols defined in the descriptor document.
      #
      # @return [Array] The protocols.
      def available_protocols
        protocols.keys
      end
      
      ## 
      # The default protocol used to send messages. If not defined explicitly in the top-level of the resource 
      # descriptor document, it defaults to the first protocol defined.
      #
      # @return [String] The protocol.
      def default_protocol
        @default_protocol ||= begin
          if default_protocol = descriptor_document['default_protocol']
            default_protocol.downcase
          elsif protocol_key = protocols.keys.first
            protocol_key
          else
            raise "No protocols defined for the resource descriptor #{id}. Please define a protocol in the " <<
              "associated descriptor document or set a 'default_protocol' for the document."
          end
        end
      end

      # Returns the profile link.
      #
      # @return [Crichton::Descriptor::Link] The link.
      def profile_link
        @descriptors[:profile_link] ||= if self_link = links['self']
          Crichton::Descriptor::Link.new(self, 'profile', self_link.href)
        end
      end
      
      ##
      # Whether the specified protocol exists or not.
      #
      # @return [Boolean] <tt>true</tt> if it exists, <tt>false</tt> otherwise.
      def protocol_exists?(protocol)
        available_protocols.include?(protocol)
      end
  
      ##
      # Returns the protocol transition descriptors specified in the resource descriptor document.
      #
      # @return [Hash] The protocol transition descriptors.
      def protocols
        @descriptors[:protocol] ||= begin
          (descriptor_document['protocols'] || {}).inject({}) do |h, (protocol, protocol_transitions)|
            klass = case protocol
                    when 'http' then Http
                    else
                      raise "Unknown protocol #{protocol} defined in resource descriptor document #{id}."
                    end
            h[protocol] = (protocol_transitions || {}).inject({}) do |transitions, (transition, transition_descriptor)|
              transitions.tap { |hash| hash[transition] = klass.new(self, transition_descriptor, transition) }
            end
            h
          end
        end
      end
      
      ##
      # Returns a protocol-specific transition descriptor.
      #
      # @param [String] protocol The protocol name.
      # @param [String] transition_name The transition name.
      #
      # @return [Object] The descriptor instance.
      def protocol_transition(protocol, transition_name)
        protocols[protocol] && protocols[protocol][transition_name] 
      end

      ##
      # Returns the states defined for the resource descriptor.
      #
      # @return [Hash] The state instances.
      def states
        @descriptors[:state] ||= (descriptor_document['states'] || {}).inject({}) do |h, (resource, state_descriptors)|
          h[resource] = (state_descriptors || {}).inject({}) do |states, (id, state_descriptor)|
            state = State.new(self, state_descriptor, id)
            states[state.name] = state
            states
          end
          h
        end.freeze
      end
  
      ##
      # Converts the descriptor to a key for registration.
      #
      # @return [String] The key.
      def to_key
        @key ||= "#{id}:#{version}"
      end
      
      private
      # TODO: Delegate to Lint when implemented.
      def verify_descriptor(descriptor)
        err_msg = ''
        err_msg << " missing id in #{descriptor.inspect}" unless descriptor['id']
        err_msg << " missing version for the resource #{descriptor['name']}." unless descriptor['version']
        
        raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
      end
    end
  end
end
