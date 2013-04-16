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
      def initialize(resource_descriptor, descriptor_document)
        @resource_descriptor = resource_descriptor
        @descriptor_document = descriptor_document && descriptor_document.dup || {}
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

      # @private
      # Overrides inspect to remove the descriptor document for readability
      def inspect
        ivars = (instance_variables - EXCLUDED_VARIABLES).map do |ivar|
          "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
        '#<%s:0x%s %s>' % [self.class.name, self.hash.to_s(16), ivars.join(", ")]
      end
    end
  end
end
