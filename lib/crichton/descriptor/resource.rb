require 'crichton/descriptor/http'
require 'crichton/descriptor/profile'
require 'crichton/descriptor/detail'
require 'crichton/descriptor/state'

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
        collect_descriptor_ids(hash_descriptor)
        # Build hash with resolved local links
        hash_descriptor_with_dereferenced_links = build_dereferenced_hash_descriptor(hash_descriptor)
        add_resource_descriptors_to_registry(hash_descriptor, raw_registry)
        add_resource_descriptors_to_registry(hash_descriptor_with_dereferenced_links, registry)
      end

      def self.add_resource_descriptors_to_registry(hash_descriptor, registry)
        new(hash_descriptor).tap do |resource_descriptor|
          resource_descriptor.descriptors.each do |descriptor|
            if registry[descriptor.id]
              raise ArgumentError, "Resource descriptor for #{descriptor.id} is already registered."
            end
            registry[descriptor.id] = descriptor
          end
        end

      end

      def self.collect_descriptor_ids(hash_descriptor)
        # dereferencing registry links
        descriptors = hash_descriptor['descriptors']
        descriptors.each do |k,v|
          build_descriptor_hashes_by_id(k, [k], nil, v)
        end
      end

      def self.build_descriptor_hashes_by_id(descriptor_id, pre_path, name, hash)
        cur_path = [pre_path, [name]].flatten.compact
        if @ids_registry.nil?
          @ids_registry = {}
        end
        if !name.nil? && @ids_registry.include?(name)
          raise "Descriptor name #{name} already in ids_registry!"
        end
        # Add descriptor to the IDs hash
        @ids_registry[cur_path.join("/")] = hash unless name.nil?

        # Descend
        unless hash['descriptors'].nil?
          hash['descriptors'].each do |k,v|
            build_descriptor_hashes_by_id(descriptor_id, cur_path, k, v)
          end
        end
      end

      def self.build_dereferenced_hash_descriptor(hash)
        new_hash = {}
        hash.each do |k,v|
          if k == 'href'
            if @ids_registry.include? v
              new_hash.merge!(@ids_registry[v])
            else
              new_hash[k] = v
            end
          elsif v.is_a? Hash
              der_ded = build_dereferenced_hash_descriptor(v)
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
  
      ##
      # Lists the registered resource descriptors.
      #
      # @return [Hash] The registered resource descriptors, if any.
      def self.registry
        @registry ||= {}
      end

      ##
      # Lists the registered resource descriptors.
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
