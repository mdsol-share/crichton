require 'active_support/core_ext/hash'

module Crichton
  ##
  # Implements a generic ALPS-related interface that represents the semantics and transitions associated with 
  # the underlying resource data.
  #
  # @example
  #   class DRD
  #     include Crichton::Representor
  #     
  #     represents :drd
  #   end
  #
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
      # Sets the resource name the object represents.
      #
      # @param [String, Symbol] resource_name The represented resource name.
      def represents(resource_name)
        @resource_name = resource_name.to_s if resource_name
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
          "#represents method in the class definition to set the associated resource name.")
      end

      private
      def filter_descriptors(descriptors, embed = nil)
        filter = embed == :embedded ? :select : :reject
        resource_descriptor.send(descriptors).values.send(filter) { |descriptor| descriptor.embeddable? }
      end
    end
    
    module InstanceMethods
      ##
      # Returns a hash populated with the data related semantic keys and underlying descriptors for the represented
      # resource.
      # 
      # @example
      #  @drd_instance.data_semantics({except: :status})   
      #  @drd_instance.data_semantics({only: [:uuid, 'name']})
      # 
      # @param [Hash] options Optional conditions.
      # @option options [String, Symbol, Array] :except The semantic data descriptor names to filter out.
      # @option options [String, Symbol, Array] :only The semantic data descriptor names to limit.
      #
      # @return [Hash] The data.
      def data_semantics(options = nil)
        each_data_semantic(options).inject({}) { |h, descriptor| h[descriptor.name] = descriptor; h }
      end

      ##
      # Returns a hash populated with the related semantic keys and underlying descriptors for embedded resources.
      # 
      # @example
      #  @drds_instance.embedded_semantics({include: :items})   
      #  @drds_instance.embedded_semantics({exclude: 'items'})
      # 
      # @param [Hash] options Optional conditions.
      # @option options [String, Symbol, Array] :include The embedded semantic descriptor names to include.
      # @option options [String, Symbol, Array] :exclude The embedded semantic descriptor names to exclude.
      #
      # @return [Hash] The embedded resources.
      def embedded_semantics(options = nil)
        each_embedded_semantic(options).inject({}) { |h, descriptor| h[descriptor.name] = descriptor; h }
      end
      
      # @private
      # Use this to load the correct enumerator.
      def method_missing(method, *args, &block)
        if method =~ /^each_(\w*)_semantic_enumerator$/
          send(:each_semantic_enumerator, $1, *args, &block)
        else
          super
        end
      end
      
    protected
      def each_data_semantic(options = nil, &block)
        each_data_semantic_enumerator(slice_known(options, :only, :except), &block)
      end

      def each_embedded_semantic(options = nil, &block)
        each_embedded_semantic_enumerator(slice_known(options, :include, :exclude), &block)
      end
      
    private
      def each_semantic_enumerator(type, options)
        return to_enum("each_#{type}_semantic", options) unless block_given?

        descriptors = self.class.send("#{type}_semantic_descriptors")
        names, select = filter_names(options)
        method = select ? :select : :reject

        descriptors = descriptors.send(method) { |descriptor| names.include?(descriptor.name) } if names

        descriptors.inject([]) do |a, descriptor|
          decorated_descriptor = Crichton::Descriptor::SemanticDecorator.new(self, descriptor)

          a.tap { |array| array << (yield decorated_descriptor) if decorated_descriptor.source_defined? }
        end
      end
      
      def filter_names(options = nil)
        options ||= {}

        if only = options[:only]
          [only, true]
        elsif except = options[:except]
          [except]
        elsif include = options[:include]
          [include, true]
        elsif exclude = options[:exclude]
          [exclude]
        else
          []
        end.tap { |filters| filters[0] = Array.wrap(filters[0]).map(&:to_s) if filters.any? }
      end
      
      def slice_known(options, *known_options)
        options ||= {}
        options.slice(*known_options)
      end
    end
  end
end
