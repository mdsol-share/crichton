module Crichton
  module Descriptor
    # Manages core profile functionality for all descriptors.
    class Profile < Base
    
      # The types of semantic descriptors.
      SEMANTIC_TYPES = %w(semantic)
    
      # The types of transition descriptors.
      TRANSITION_TYPES = %w(safe unsafe idempotent)
    
      # @!macro string_reader
      descriptor_reader :doc
    
      # @!macro string_reader
      descriptor_reader :id
    
      ##
      # @!attribute descriptors [r]
      # The nested descriptors.
      #
      # @return [Array] The descriptor instances.
      def descriptors
        @descriptors[:all] ||= begin
          (descriptor_document['descriptors'] || []).map do |descriptor_section|
            klass = SEMANTIC_TYPES.include?(descriptor_section['type']) ? Semantic : Transition
            klass.new(resource_descriptor, descriptor_section)
          end.freeze
        end
      end
    
      ##
      # @!attribute [r] links
      # Returns the descriptor links as hashes.
      #
      # @return [Array] The link objects.
      def links
        @links ||= (descriptor_document['links'] || [])
      end

      ##
      # Whether the descriptor is a semantic descriptor.
      #
      # @return [Boolean] true, if a semantic descriptor.
      def semantic?
        SEMANTIC_TYPES.include?(type)
      end

      ##
      # @!attribute semantics [r]
      # The nested semantic descriptors keyed by descriptor name.
      #
      # @return [Hash] The semantic descriptor instances.
      def semantics
        @descriptors[:semantic] ||= filter_descriptors(:semantic)
      end
      
      ##
      # Whether the descriptor is a transition descriptor.
      #
      # @return [Boolean] true, if a transition descriptor.
      def transition?
        TRANSITION_TYPES.include?(type)
      end
      ##
      # @!attribute transitions [r]
      # The nested transition descriptors keyed by descriptor name.
      #
      # @return [Hash] The transition descriptor instances.
      def transitions
        @descriptors[:transition] ||= filter_descriptors(:transition)
      end
      
      private
      def filter_descriptors(type)
        descriptors.inject({}) do |h, descriptor|
          h.tap { |hash| hash[descriptor.name] = descriptor if descriptor.send("#{type}?") }
        end.freeze
      end
    end
  end
end
