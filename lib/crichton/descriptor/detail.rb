require 'crichton/descriptor/profile'

module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @!macro string_reader
      descriptor_reader :href

      # @!macro string_reader
      descriptor_reader :embed

      # @!macro string_reader
      descriptor_reader :rt

      # @!macro object_reader
      descriptor_reader :sample

      # @!macro string_reader
      descriptor_reader :type
      
      ##
      # Constructs a new instance of BaseDocumentDescriptor.
      #
      # Subclasses MUST call <tt>super</tt> in their constructors.
      #
      # @param [Crichton::Descriptor::Resource] resource_descriptor The top-level resource descriptor instance.   
      # @param [Crichton::Descriptor::Base] parent_descriptor The parent descriptor instance.                                                            # 
      # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
      def initialize(resource_descriptor, parent_descriptor, descriptor_document)
        super(resource_descriptor, descriptor_document)
        @descriptors[:parent] = parent_descriptor
      end
      
      ##
      # Decorates a descriptor to access associated properties from a target.
      #
      # @param [Object] target The target.
      # @param [Hash] options Optional conditions.
      #
      # @return [Crichton::Descriptor::SemanticDecorator, Crichton::Descriptor::TransitionDecorator] The decorated 
      #   descriptor.
      def decorate(target, options = nil)
        decorator_class.new(target, self, options)
      end
      
      ##
      # Whether the descriptor is embeddable or not as indicated by the presence of an embed key in the
      # underlying resource descriptor document.
      #
      # @return [Boolean] <tt>true</tt> if embeddable. <tt>false</tt> otherwise.
      def embeddable?
        !!embed
      end
      
      ##
      # Returns the parent descriptor of a nested-descriptor.
      #
      # @return [Crichton::Descriptor::Base] The parent descriptor.
      def parent_descriptor
        @descriptors[:parent]
      end

      ##
      # The source of the descriptor. Used to specify the local attribute associated with the semantic descriptor
      # name that is returned. Only set this value if the name is different than the source in the local object.
      #
      # @return [String] The source of the semantic descriptor.
      def source
        descriptor_document['source'] || name
      end
      
    private
      def decorator_class
        @decorator_class ||= begin
          require 'crichton/descriptor/semantic_decorator'
          require 'crichton/descriptor/transition_decorator'
          
          semantic? ? SemanticDecorator : TransitionDecorator
        end
      end
    end
  end
end
