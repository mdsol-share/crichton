module Crichton
  ##
  # Manages Resource Descriptor parsing and consumption for use decorating service responses or interacting with
  # Hypermedia types.
  class ResourceDescriptor < BaseDescriptor
    ##
    # Clears all registered resource descriptors
    def self.clear
      @registered_resources = nil
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

      ResourceDescriptor.new(hash_descriptor).tap do |resource|
        if registered_resources[resource.id]
          raise ArgumentError, "Resource descriptor for #{resource.id} is already registered." 
        end
          
        registered_resources[resource.id] = resource 
      end
    end

    ##
    # Lists the registered resources.
    #
    # @return [Hash] The registered resource descriptors, if any.
    def self.registered_resources
      @registered_resources ||= {}
    end

    ##
    # Whether any resource descriptors have been registered or not.
    #
    # @return [Boolean] true, if any resource descriptors are registered.
    def self.registered_resources?
      !!(@registered_resources && !@registered_resources.empty?)
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
    # The entry_point, keyed by protocol, of the resource descriptor.
    #
    # @return [Hash] The entry point objects.
    def entry_point
      descriptor_document['entry_point']
    end

    ##
    # The version of the resource descriptor.
    #
    # @return [String] The version of the resource.
    def version
      descriptor_document['version']
    end

    # TODO: Delegate to Lint when implemented.
    def verify_descriptor(descriptor)
      err_msg = ''
      err_msg << " missing id in #{descriptor.inspect}" unless descriptor['id']
      err_msg << " missing name in #{descriptor.inspect}" unless descriptor['name']
      err_msg << " missing version for the resource #{descriptor['name']}." unless descriptor['version']
      
      raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
    end
  end
end
