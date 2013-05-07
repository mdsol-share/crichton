module Crichton
  ##
  # Implements a generic ALPS-related interface that represents the semantics and transitions associated with 
  # the underlying resource data. 
  module Representor
      
    # @private
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include InstanceMethods
      end
    end
    
    module ClassMethods
      ##
      # The data-related semantic descriptors defined for the associated resource descriptor.
      #
      # @return [Array] The data related semantic descriptors.
      def data_semantic_descriptors
        @data_semantics ||= filter_descriptors(:semantics)
      end

      ##
      # The embedded-resource related semantic descriptors defined for the associated resource descriptor.
      #
      # @return [Array] The embedded semantic descriptors.
      def embedded_semantic_descriptors
        @embedded_semantics ||= filter_descriptors(:semantics, :embedded)
      end

      ##
      # The embedded-resource related transition descriptors defined for the associated resource descriptor.
      #
      # @return [Array] The embedded transition descriptors.
      def embedded_transition_descriptors
        @embedded_transitions ||= filter_descriptors(:transitions, :embedded)
      end

      ##
      # The link related transition descriptors defined for the associated resource descriptor.
      #
      # @return [Array] The link transition descriptors.
      def link_transition_descriptors
        @link_transitions ||= filter_descriptors(:transitions)
      end

      ##
      # The descriptor associated with resource being represented.
      #
      # @return [Crichton::Descriptor::Detail] The resource descriptor.
      def resource_descriptor
        Crichton.registry[resource_name]
      end
      
      ##
      # The name of the resource to be represented.
      #
      # @return [String] The resource name.
      def resource_name
        @resource_name || raise("No resource name has been defined#{self.name ? ' for ' << self.name : ''}. Use " <<
          "#set_resource_name in the class definition to set the associated resource name.")
      end

      private
      def set_resource_name(value)
        @resource_name = value.to_s if value
      end
      
      def filter_descriptors(descriptors, embed = nil)
        filter = embed == :embedded ? :select : :reject
        resource_descriptor.send(descriptors).values.send(filter) { |descriptor| descriptor.embeddable? }
      end
    end
    
    module InstanceMethods
      ##
      # Returns a hash populated with the data related semantic keys and underlying values for the represented
      # resource.
      # 
      # @return [Hash] The data.
      def data_semantics
        # This method is not memoized so that local changes are always picked up. 
        # TODO: Look at using ActiveModel::Dirty to allow clearing memoization
        semantic_hash(:data_semantic_descriptors)
      end

      ##
      # Returns a hash populated with the related semantic keys and underlying values for embedded resources.
      # 
      # @return [Hash] The embedded resources.
      def embedded_semantics
        # This method is not memoized so that local changes are always picked up. 
        # TODO: Look at using ActiveModel::Dirty to allow clearing memoization
        semantic_hash(:embedded_semantic_descriptors)
      end
      
      private
      def semantic_hash(descriptors)
        self.class.send(descriptors).inject({}) do |h, descriptor|
          h.tap { |hash| hash[descriptor.name] = self.send(descriptor.source) if self.respond_to?(descriptor.source) }
        end
      end
    end
  end
end
