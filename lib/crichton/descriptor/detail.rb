require 'crichton/descriptor/profile'
require 'crichton/descriptor/options'

module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @private
      SAFE = 'safe'

      # @private
      MULTIPLE = 'multiple'

      # @private
      CARDINALITY = 'cardinality'

      # @private
      OPTIONS = 'options'

      # @!macro string_reader
      descriptor_reader :embed

      # @!macro string_reader
      descriptor_reader :field_type

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
        @descriptors[:descriptor_name] = parent_descriptor.name
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

      SINGLE_MULTIPLE = %w(single multiple)
      SINGLE_LINK_MULTIPLE_LINK = %w(single-link multiple-link)
      SINGLE_OPTIONAL_MULTIPLE_OPTIONAL = %w(single-optional multiple-optional)
      SINGLE_OPTIONAL_MULTIPLE_OPTIONAL_LINK = %w(single-optional-link multiple-optional-link)

      EMBED_VALUES = SINGLE_MULTIPLE + SINGLE_LINK_MULTIPLE_LINK + SINGLE_OPTIONAL_MULTIPLE_OPTIONAL +
        SINGLE_OPTIONAL_MULTIPLE_OPTIONAL_LINK
      ##
      # Determines how embedded elements should be embedded
      #
      # @return [Symbol, NilClass] Either :embed or :link
      def embed_type(options)
        if SINGLE_MULTIPLE.include?(embed)
          :embed
        elsif SINGLE_LINK_MULTIPLE_LINK.include?(embed)
          :link
        elsif SINGLE_OPTIONAL_MULTIPLE_OPTIONAL.include?(embed)
          options[:embed_optional] && options[:embed_optional][self.name] || :embed
        elsif SINGLE_OPTIONAL_MULTIPLE_OPTIONAL_LINK.include?(embed)
          options[:embed_optional] && options[:embed_optional][self.name] || :link
        else
          :embed
        end
      end

      ##
      # Returns an array of the profile, type and help links associated with the descriptor.
      #
      # @return [Array] The link instances.
      def metadata_links
        @metadata_links ||= [profile_link, type_link, help_link].compact
      end
      
      def options
        @options ||= Options.new(descriptor_document[OPTIONS] || {})
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
          Crichton::Descriptor::Link.new(resource_descriptor, 'type', self_link.absolute_href)
        end
      end

      ##
      # Whether descriptor has scope attribute. If it has, considered to be parameter for url.
      def scope?
        descriptor_document['scope'].present?
      end

      ##
      # Whether descriptor has multiple property.
      def multiple?
        (cardinality = descriptor_document[CARDINALITY]).present? && cardinality == MULTIPLE
      end

      ##
      # Whether descriptor is resource descriptor. It is resource descriptor if it has states defined.
      def resource?
        descriptor_document[Crichton::Descriptor::STATES].present?
      end

      ##
      # Returns attributes associated with descriptor.
      #
      # @return [Hash] Attributes.
      def validators
        @validators ||= [*descriptor_document['validators']].map { |v| v.is_a?(String) ? { v => nil } : v }.inject({}, :update)
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
