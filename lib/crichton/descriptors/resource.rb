module Crichton
  ##
  # Clears any registered resource descriptors.
  def self.clear_resource_descriptors
    @registered_resource_descriptors = nil
    Descriptors::Resource.clear
  end
  
  ##
  # Returns the registered resources.
  #
  # If a directory containing YAML resource descriptor files is configured, it automatically loads all resource
  # descriptors in that location.
  #
  # @@return [Hash] The registered resource descriptors, if any?
  def self.resource_descriptors
    unless @registered_resource_descriptors
      unless Descriptors::Resource.registered_resources?
        if (location = config.resource_descriptors_location) && File.exists?(location)
          Dir[File.join(location, '*.yml')].each do |f|
            resource_descriptor = YAML.load_file(f)
            Descriptors::Resource.register(resource_descriptor)
          end
        end
      end
      @registered_resource_descriptors = Descriptors::Resource.registered_resources
    end
    @registered_resource_descriptors
  end
  
  module Descriptors
    ##
    # Manages Resource Descriptor parsing and consumption for use decorating service responses or interacting with
    # Hypermedia types.
    class Resource
      class << self
        
        ##
        # Clears all registered resource descriptors
        def clear
          @registered_resources = nil
          @raw_resources = nil
        end
        
        ##
        # Whether any resource descriptors have been registers or not.
        #
        # @return [Boolean] true, if any resource descriptors are registered.
        def registered_resources?
          !!(@registered_resources && !@registered_resources.empty?)
        end
        
        ##
        # Registers a resource descriptor document by name and version.
        #
        # @param [Hash] descriptor The hashified resource descriptor document.
        def register(descriptor)
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
        def registered_resources
          @registered_resources ||= {}
        end

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
        verify_descriptor!(resource_descriptor)
        
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
      def verify_descriptor!(descriptor)
        err_msg = ''
        err_msg << " missing name in #{descriptor.inspect}" unless descriptor['name']
        err_msg << " missing version for the resource #{descriptor['name']}." unless descriptor['version']
        
        raise ArgumentError, 'Resource descriptor:' << err_msg unless err_msg.empty?
      end
    end
  end
end
