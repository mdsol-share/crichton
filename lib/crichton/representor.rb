require 'active_support/concern'
require 'crichton/representor/serialization/media_type'
require 'crichton/representor/options'

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
    extend ActiveSupport::Concern

    included do
      include Serialization::MediaType
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
        Crichton.descriptor_registry[resource_name]
      end

      ##
      # The name of the resource to be represented.
      #
      # @return [String] The resource name.
      def resource_name
        @resource_name || raise(Crichton::RepresentorError,
          "No resource name has been defined#{self.name ? ' for ' << self.name : ''}. " <<
          "Use #represents method in the class definition to set the associated resource name.")
      end

    private
      def filter_descriptors(descriptors, embed = nil)
        filter = embed == :embedded ? :select : :reject
        resource_descriptor.send(descriptors).values.send(filter) { |descriptor| descriptor.embeddable? }
      end
    end

    def options(options_hash)
      Options.new(options_hash, self)
    end

    ##
    # Returns a hash populated with the data related semantic keys and underlying descriptors for the represented
    # resource.
    # 
    # @example
    #  @drd_instance.each_data_semantic({except: :status}).to_a   
    #  @drd_instance.each_data_semantic({only: [:uuid, 'name']}).to_a
    # 
    # @param [Hash] options Optional conditions.
    # @option options [String, Symbol, Array] :except The semantic data descriptor names to filter out.
    # @option options [String, Symbol, Array] :only The semantic data descriptor names to limit.
    #
    # @return [Hash] The data.
    def each_data_semantic(options = nil)
      return to_enum(:each_data_semantic, options) unless block_given?
      each_enumerator(:data, :semantic, options, &Proc.new)
    end

    ##
    # Returns a hash populated with the related semantic keys and underlying descriptors for embedded resources.
    # 
    # @example
    #  @drds_instance.each_embedded_semantic({include: :items}).to_a   
    #  @drds_instance.each_embedded_semantic({exclude: 'items'}).to_a
    # 
    # @param [Hash] options Optional conditions.
    # @option options [String, Symbol, Array] :include The embedded semantic descriptor names to include.
    # @option options [String, Symbol, Array] :exclude The embedded semantic descriptor names to exclude.
    #
    # @return [Hash] The embedded resources.
    def each_embedded_semantic(options = nil)
      return to_enum(:each_embedded_semantic, options) unless block_given?
      each_enumerator(:embedded, :semantic, options, &Proc.new)
    end

    ##
    # Returns a hash populated with the data related semantic keys and underlying descriptors for the represented
    # and embedded resource.
    #
    # @example
    #  @drd_instance.each_transition({except: :delete}).to_a
    #  @drd_instance.each_transition({only: [:show, 'activate']}).to_a
    #  @drd_instance.each_transition({state: :activated, conditions: :can_do_anything}).to_a
    #
    # @param [Hash] options Optional conditions.
    # @option options [String, Symbol, Array] :conditions The state conditions.
    # @option options [String, Symbol, Array] :except The link transition descriptors to filter out.
    # @option options [String, Symbol, Array] :only The link transition descriptors to limit.
    # @option options [String, Symbol, Array] :state The state of the resource.
    #
    # @return [Hash] The data.
    def each_transition(options = nil)
      return to_enum(:each_transition, options) unless block_given?
      each_enumerator(:link, :transition, options, &Proc.new)
      each_additional_link_transition_enumerator(options, &Proc.new)
      each_enumerator(:embedded, :transition, options, &Proc.new)
    end

    ##
    # Find and return the self transition
    #
    # @return [Hash] The data.
    def self_transition
      @_self_transition ||= Crichton.descriptor_registry[self.class.resource_name].self_transition.decorate(self, {})
    end

    ##
    # Returns the profile, type and help links of the associated descriptor.
    #
    # @return [Array] The link instances.
    def metadata_links(*)
      self.class.resource_descriptor.metadata_links
    end

  private
    AdditionalTransition = Struct.new :name, :url
    private_constant :AdditionalTransition

    def each_additional_link_transition_enumerator(options)
      if options.is_a?(Hash) && options[:top_level] && options[:additional_links]
        options[:additional_links].map do |relation, url|
          # We don't use url because we want to clear out the data from the options
          transition = AdditionalTransition.new(relation, options[:additional_links].delete(relation))
          yield transition if block_given?
          transition
        end
      else
        []
      end
    end

    def each_enumerator(type, descriptor, options)
      unless options.nil? || options.is_a?(Hash)
        raise ArgumentError, "options must be nil or a hash. Received '#{options.inspect}'."
      end

      filtered_descriptors(type, descriptor, options).each do |descriptor| 
        # For semantic descriptors, use the target in case it is a hash adapter. For transition descriptors, use
        # the actual Representor instance which implements state functionality regardless.
        decorated_descriptor = descriptor.decorate(descriptor.semantic? ? target : self, options)
        yield decorated_descriptor if decorated_descriptor.available?
      end
    end
    
    def filtered_descriptors(type, descriptor, options)
      descriptors = self.class.send("#{type}_#{descriptor}_descriptors")
      filter_options = parsed_filtering_options(options || {})
      descriptors.map { |descriptor| descriptor if descriptor_to_be_included(descriptor.name, filter_options) }.compact
    end

    def descriptor_to_be_included(name, filter_options)
      return true if filter_options.nil?
      return false if filter_options[:only].present? && !filter_options[:only].include?(name)
      return true if filter_options[:include].include?(name)
      return false if filter_options[:remove].include?(name)
      return true # if not excluded
    end

    def parsed_filtering_options(options = {})
      filtering_options = {
        include: [options[:include] || []].flatten,
        remove: [[options[:except] || []] + [options[:exclude] || []]].flatten.map(&:to_s),
        only: [options[:only] || []].flatten.map(&:to_s)
      }
      filtering_options.values.all? { |v| v.empty? } ? nil : filtering_options
    end

    def target
      # @target will only be set in a Factory adapter instance.
      @target ||= self
    end

    ##
    # Allows an object to define the method Crichton should use to determine the state. This prevents collisions
    # with, for example, an address object that includes a <tt>state</tt> attribute.
    module State
      extend ActiveSupport::Concern

      included do
        include Representor
      end
      
      module ClassMethods
        ##
        # Sets the state method Crichton should use for the class.
        # 
        # @example
        #   class DRD
        #     include Crichton::Representor::State
        #     represents   :drd
        #
        #   end
        #   DRD.respond_to?(:state) # => true
        #   
        #   
        #   class Address
        #     include Crichton::Representor::State
        #     represents   :address
        #     state_method :my_state_method
        #
        #     attr_accessor :city, :state, :zip
        #
        #     def my_state_method
        #       # Do something to determine the state of the resource.
        #     end
        #   end
        #
        # @param [String, Symbol] method The method.
        def state_method(method)
          @crichton_state_method = method.to_s if method
        end
        
      private
        def crichton_state_method(representor)
          @crichton_state_method ||= if representor.respond_to?(:state)
            :state
          else
            raise(Crichton::RepresentorError,
              "No state method has been defined in the class '#{self.name}'. Please specify a " <<
              "state method using the class method #state_method or define an instance method #state on the class.")
          end
        end
      end
      
      def crichton_state
        @crichton_state ||= begin
          state_method = self.class.send(:crichton_state_method, self)
          state = if self.respond_to?(state_method)
            instance_state(state_method)
          elsif target.is_a?(Hash)
            hash_state(state_method)
          else
            target_state(state_method)
          end
          
          state.tap do |state|
            unless [String, Symbol].include?(state.class)
              raise(Crichton::RepresentorError,
                "The state method '#{state_method }' must return a string or a symbol. " <<
                "Returned #{state.inspect}.") 
            end
          end
        end
      end
      
    private
      def instance_state(state_method)
        send(state_method) || raise(Crichton::RepresentorError,
          "The state was nil in the class '#{self.class.name}'. Please check " <<
          "the class properly implements a response associated with the state method '#{state_method}.'")
      end
      
      def hash_state(state_method)
        unless state_key = target.keys.detect { |k| k.to_s == state_method }
          raise(Crichton::RepresentorError,
            "No attribute exists in the target '#{@target.inspect}' that corresponds to the state method " <<
            "'#{state_method}'. In a hash target, it must contain an attribute that corresponds to the state method.")
        end
        @target[state_key]
      end

      def target_state(state_method)
        if target.respond_to?(state_method)
          target.send(state_method)
        else
          raise(Crichton::RepresentorError,
            "The state method #{state_method} is not implemented in the target #{target.inspect}. " <<
            "Please ensure this state method is defined.")
        end
      end
    end
    
  end
end
