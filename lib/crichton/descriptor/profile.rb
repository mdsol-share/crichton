require 'crichton/descriptor/base'
require 'crichton/descriptor/link'
require 'crichton/alps/serialization'

module Crichton
  
  module Descriptor
    # Manages core profile functionality for all descriptors.
    class Profile < Base
      include ALPS::Serialization
    
      # The types of semantic descriptors.
      SEMANTIC_TYPES = %w(semantic)
    
      # The types of transition descriptors.
      TRANSITION_TYPES = %w(safe unsafe idempotent)

      # Complete list of transition_descriptors
      DESCRIPTOR_TYPES = SEMANTIC_TYPES + TRANSITION_TYPES

      ##
      # @!attribute descriptors [r]
      # The nested descriptors.
      #
      # @return [Array] The descriptor instances.

      def self_transition
        descriptors unless @self_transition
        @self_transition
      end

      def descriptors
        @descriptors[:all] ||= begin
          doc = descriptor_document[Crichton::Descriptor::TAG].is_a?(Hash) && descriptor_document[Crichton::Descriptor::TAG] || {}
          doc.keys.map do |id|
            descriptor = Detail.new(resource_descriptor, self, id)
            @self_transition = descriptor if descriptor.name == 'self' && descriptor.transition?
            descriptor
          end.freeze
        end
      end

      ##
      # Returns the resources defined for the resource descriptor.
      #
      # @return [Array] List of [Crichton::Descriptor::Detail] object which represent resources.
      def resources
        @descriptors[:resources] ||= begin
          descriptors.select{ |descriptor| descriptor.descriptor_document[Crichton::Descriptor::STATES].present? }
        end
      end

      # Returns the descriptor help link descriptor. If no help link is defined on the descriptor is defined, it 
      # returns the resource descriptor help link.
      #
      # @return [Crichton::Descriptor::Link] The link.
      def help_link
        links['help'] || resource_descriptor.help_link
      end

      # @!macro string_reader
      descriptor_reader :ext
      ##
      # @!attribute [r] links
      # Returns the descriptor links as hashes.
      #
      # @return [Array] The link objects.
      def links
        @links ||= (descriptor_document['links'] || {}).inject({}) do |h, (rel, href)|
          h.tap { |hash| hash[rel] = Link.new(self, rel, href)}
        end
      end
      alias :link :links # ALPS expects a singular property name.

      ##
      # Whether the descriptor is a semantic descriptor.
      #
      # @return [Boolean] true, if a semantic descriptor.
      def semantic?
        @semantic ||= SEMANTIC_TYPES.include?(type)
      end

      ##
      # @!attribute semantics [r]
      # The nested semantic descriptors keyed by descriptor name.
      #
      # @return [Hash] The semantic descriptor instances.
      def semantics
        @descriptors[:semantic] ||= filter_descriptors(:semantic, :name)
      end
      
      ##
      # Whether the descriptor is a transition descriptor.
      #
      # @return [Boolean] true, if a transition descriptor.
      def transition?
        @transition ||= TRANSITION_TYPES.include?(type)
      end
      
      ##
      # @!attribute transitions [r]
      # The nested transition descriptors keyed by descriptor name.
      #
      # @return [Hash] The transition descriptor instances.
      def transitions
        @descriptors[:transition] ||= filter_descriptors(:transition, :id)
      end
      
      private
      def filter_descriptors(type, property)
        descriptors.inject({}) do |h, descriptor|
          h.tap { |hash| hash[descriptor.send(property)] = descriptor if descriptor.send("#{type}?") }
        end.freeze
      end
    end
  end
end
