module Crichton
  module Descriptors
    ##
    # Manages Resource Descriptor parsing and consumption for use decorating service responses or interacting with
    # Hypermedia types.
    class Resource
      ##
      # Clears all registered resource descriptors
      def self.clear
        @registered_resources = nil
        @raw_resources = nil
      end
      
      ##
      # Whether any resource descriptors have been registered or not.
      #
      # @return [Boolean] true, if any resource descriptors are registered.
      def self.registered_resources?
        !!(@registered_resources && !@registered_resources.empty?)
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
  
        Resource.new(hash_descriptor).tap do |resource|
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

      class << self
        private
        def raw_resources
          @raw_resources ||= {}
        end
      end
      
      ##
      # Constructor
      #
      # @param [Hash] resource_descriptor The resource descriptor hash.
      def initialize(resource_descriptor)
        verify_descriptor(resource_descriptor)
        
        @id = descriptor_key(resource_descriptor)
        
        # For this class to function, it must register its raw resource descriptor. See private method 
        # #resource_descriptor below.
        self.class.instance_exec(@id, resource_descriptor) do |key, descriptor| 
          raw_resources[key] = descriptor unless raw_resources[key]
        end
      end
      
      ##
      # The id of resource descriptor, which is the name:version of the underlying resource descriptor.
      attr_accessor :id

      ##
      # The description of the resource.
      #
      # @return [String] The description.
      def doc
        resource_descriptor['doc']
      end

      ##
      # The name of the resource.
      #
      # @return [String] The name of the resource.
      def name
        resource_descriptor['name']
      end

      ##
      # The version of the resource.
      #
      # @return [String] The version of the resource.
      def version
        resource_descriptor['version']
      end
      
      private
      def descriptor_key(descriptor)
        "#{descriptor['name']}:#{descriptor['version']}"
      end

      # Used to reference the raw resource descriptor internally without polluting #inspect with
      # large hash objects associated with the underlying document.
      def resource_descriptor
        self.class.instance_exec(@id) { |key| raw_resources[key] }
      end

      # TODO: Delegate to Lint when implemented.
      def verify_descriptor(descriptor)
        err_msg = ''
        err_msg << " missing name in #{descriptor.inspect}" unless descriptor['name']
        err_msg << " missing version for the resource #{descriptor['name']}." unless descriptor['version']
        
        raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
      end
    end
  end
end
