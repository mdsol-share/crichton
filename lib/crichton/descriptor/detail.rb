require 'crichton/descriptor/profile'

module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @private
      SAFE = 'safe'
      
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
      def initialize(resource_descriptor, parent_descriptor, id, descriptor_document = nil)
        # descriptor_document argument not documented since used internally by decorator classes for performance.
        descriptor_document ||= parent_descriptor.child_descriptor_document(id)
        super(resource_descriptor, descriptor_document, id)
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
      # Returns an array of the profile, type and help links associated with the descriptor.
      #
      # @return [Array] The link instances.
      def metadata_links
        @metadata_links ||= [profile_link, type_link, help_link].compact
      end
      
      ##
      # Returns the parent descriptor of a nested-descriptor.
      #
      # @return [Crichton::Descriptor::Base] The parent descriptor.
      def parent_descriptor
        @descriptors[:parent]
      end

      ##
      # Whether the descriptor is an ALPS <tt>safe</tt> type, which will only be true for safe transitions.
      def safe?
        type == SAFE
      end

      ##
      # The source of the descriptor. Used to specify the local attribute associated with the semantic descriptor
      # name that is returned. Only set this value if the name is different than the source in the local object.
      #
      # @return [String] The source of the semantic descriptor.
      def source
        descriptor_document['source'] || name
      end
      
      def type_link
        @descriptors[:type_link] ||= if semantic? && (self_link = links['self'])
          Crichton::Descriptor::Link.new(resource_descriptor, 'type', absolute_link(self_link.href, 'type'))
        end
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
