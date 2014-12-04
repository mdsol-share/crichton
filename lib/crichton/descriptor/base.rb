require 'crichton/helpers'

module Crichton
  module Descriptor
    # Manage base functionality for all descriptors that encapsulate a section of a resource descriptor document.
    #
    # Adds a private class method <tt>descriptor_reader</tt> to descriptor classes to simplify generating
    # class specific accessors encapsulating properties in an underlying descriptor document. 
    #
    # The following macro tags add the corresponding type to the generated documentation:
    #
    #  - array_reader
    #  - hash_reader
    #  - object_reader
    #  - string_reader
    #
    # @example
    #   class Profile < base
    #     @!macro string_reader
    #     descriptor_reader: id
    #   end
    class Base
      include Crichton::Helpers::ConfigHelper

      # @private
      EXCLUDED_VARIABLES = %w(@descriptors @descriptor_document @resource_descriptor).map(&:to_sym)

      # @private
      # See lib/crichton.rb for documentation if re-usable macro definitions.
      def self.descriptor_reader(name)
        method = name.to_s
        define_method(method) do
          descriptor_document[method]
        end
      end
      private_class_method :descriptor_reader

      ##
      # Constructs a new instance of BaseDocumentDescriptor.
      #
      # Subclasses MUST call <tt>super</tt> in their constructors.
      #
      # @param [Hash] resource_descriptor The parent resource descriptor instance.                                                              # 
      # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
      # @param [Hash] id The id of the ALPS descriptor
      def initialize(resource_descriptor, descriptor_document, id = nil)
        @resource_descriptor = resource_descriptor
        @descriptor_document = descriptor_document.dup
        @descriptor_document['id'] = id.to_s if id
        @descriptors = {}
        
      end
  
      ##
      # The underlying descriptor document.
      #
      # @return [Hash] The descriptor document.
      attr_reader :descriptor_document
  
      ##
      # The parent resource descriptor.
      #
      # @return [Hash] The resource descriptor.
      attr_reader :resource_descriptor

      # @!macro string_reader
      descriptor_reader :doc

      # @!macro string_reader
      descriptor_reader :id

      # @!macro string_reader
      descriptor_reader :href
      
      # @!macro string_reader
      descriptor_reader :descriptor_type
      
      ##
      # Accesses the child descriptor document hash so inheriting classes that implement parents set
      # it directly from the parent.
      #
      # @return [Hash] The descriptor document.
      def child_descriptor_document(id)
        (descriptor_document['descriptors'] || {})[id.to_s] 
      end

      ##
      # @!attribute [r] name
      # The name of the descriptor.
      #
      # Defaults to the id of the descriptor unless a <tt>name</tt> is explicitly specified. This is necessary when
      # the associated id is modified to make it unique compared to an existing id for another descriptor.
      #
      # @return [String] The descriptor name.
      def name
        descriptor_document['name'] || id
      end
      
      ##
      # Returns the profile link for the resource descriptor.
      #
      # @return [Crichton::Descriptor::Link] The link.
      def profile_link
        resource_descriptor.profile_link
      end

      # @private
      # Overrides inspect to remove the descriptor document for readability
      def inspect
        ivars = (instance_variables - EXCLUDED_VARIABLES).map do |ivar|
          "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
        '#<%s:0x%s %s %s>' % [self.class.name, self.hash.to_s(16), self.name, ivars.join(", ")]
      end
      
    end
  end
end
