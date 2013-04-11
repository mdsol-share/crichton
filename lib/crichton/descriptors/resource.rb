require 'crichton/descriptors/nested'

module Crichton
  ##
  # Manages Resource Descriptor parsing and consumption for decorating service responses or interacting with
  # Hypermedia types.
  class ResourceDescriptor < BaseSemanticDescriptor
    include NestedDescriptors
    
    ##
    # Clears all registered resource descriptors
    def self.clear_registry
      @registry = nil
    end
    
    ##
    # Registers a resource descriptor document by name and version.
    #
    # @param [Hash, String] descriptor The hashified resource descriptor document or filename of a YAML resource 
    # descriptor document.
    def self.register(descriptor)
      hash_descriptor = case descriptor
      when String
        raise ArgumentError, "Filename #{descriptor} is not valid." unless File.exists?(descriptor)
        YAML.load_file(descriptor)
      when Hash
        descriptor
      else
        raise ArgumentError, "Document #{descriptor} must be a String or a Hash."
      end

      ResourceDescriptor.new(hash_descriptor).tap do |descriptor|
        if registry[descriptor.to_key]
          raise ArgumentError, "Resource descriptor for #{descriptor.id} is already registered." 
        end
          
        registry[descriptor.to_key] = descriptor 
      end
    end

    ##
    # Lists the registered resources descriptors.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def self.registry
      @registry ||= {}
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
    # @param [Hash] descriptor_document The resource descriptor hash.
    def initialize(descriptor_document, options = {})
      super
      verify_descriptor(descriptor_document)
    end
    
    ##
    # Returns the protocol transition descriptors specified in the resource descriptor document.
    #
    # @return [Hash] The protocol transition descriptors.
    def protocols
      @protocol_descriptors ||= begin
        (descriptor_document['protocols'] || {}).inject({}) do |h, (protocol, protocol_transitions)|
          klass = case protocol
                  when 'http' then HttpDescriptor
                  end
          h[protocol] = (protocol_transitions || {}).inject({}) do |transitions, (transition, transition_descriptor)|
            transitions[transition] = klass.new(self, transition_descriptor, id: transition)
            transitions
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
    # Converts the descriptor to a key for registration.
    #
    # @return [String] The key.
    def to_key
      "#{id}:#{version}"
    end

    ##
    # The version of the resource descriptor.
    #
    # @return [String] The version of the resource.
    def version
      descriptor_document['version']
    end
    
    private
    # Implements method for the module NestedDescriptors
    def resource_descriptor
      self
    end

    # TODO: Delegate to Lint when implemented.
    def verify_descriptor(descriptor)
      err_msg = ''
      err_msg << " missing id in #{descriptor.inspect}" unless descriptor['id']
      err_msg << " missing version for the resource #{descriptor['name']}." unless descriptor['version']
      
      raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
    end
  end
end
