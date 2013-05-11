require 'active_support/concern'

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
        @resource_name || raise(Error, "No resource name has been defined#{self.name ? ' for ' << self.name : ''}. " <<
          "Use #represents method in the class definition to set the associated resource name.")
      end

    private
      def filter_descriptors(descriptors, embed = nil)
        filter = embed == :embedded ? :select : :reject
        resource_descriptor.send(descriptors).values.send(filter) { |descriptor| descriptor.embeddable? }
      end
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
    def each_data_semantic(options = nil, &block)
      each_data_semantic_enumerator(slice_known(options, :only, :except), &block)
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
    def each_embedded_semantic(options = nil, &block)
      each_embedded_semantic_enumerator(slice_known(options, :include, :exclude), &block)
    end

    ##
    # Returns a hash populated with the related semantic keys and underlying descriptors for embedded resources.
    # 
    # @example
    #  @drds_instance.each_embedded_semantic({include: :items}).to_a   
    #  @drds_instance.each_embedded_semantic({exclude: 'items'}).to_a
    # 
    # @param [Hash] options Optional conditions.
    # @option options [String, Symbol, Array] :conditions The state conditions.
    # @option options [String, Symbol, Array] :except The embedded transition descriptors to filter out.
    # @option options [String, Symbol, Array] :only The embedded transition descriptors to limit.
    # @option options [String, Symbol, Array] :state The state of the resource.
    #
    # @return [Hash] The embedded resources.
    def each_embedded_transition(options = nil, &block)
      each_embedded_transition_enumerator(slice_known(options, :include, :exclude, :state, :conditions), &block)
    end

    ##
    # Returns a hash populated with the data related semantic keys and underlying descriptors for the represented
    # resource.
    # 
    # @example
    #  @drd_instance.each_link_transition({except: :delete}).to_a   
    #  @drd_instance.each_link_transition({only: [:show, 'activate']}).to_a
    #  @drd_instance.each_link_transition({state: :activated, conditions: :can_do_anything}).to_a
    # 
    # @param [Hash] options Optional conditions.
    # @option options [String, Symbol, Array] :conditions The state conditions.
    # @option options [String, Symbol, Array] :except The link transition descriptors to filter out.
    # @option options [String, Symbol, Array] :only The link transition descriptors to limit.
    # @option options [String, Symbol, Array] :state The state of the resource.
    #
    # @return [Hash] The data.
    def each_link_transition(options = nil, &block)
      each_link_transition_enumerator(slice_known(options, :only, :except, :state, :conditions), &block)
    end

    # @private
    # Used to return the correct enumerator.
    def method_missing(method, *args, &block)
      if method =~ /^each_(\w*)_(\w*)_enumerator$/
        send(:each_enumerator, $1, $2.to_sym, *args, &block)
      else
        super
      end
    end 
    
  private
    def each_enumerator(type, descriptor, options)
      return to_enum("each_#{type}_#{descriptor}", options) unless block_given?

      filtered_semantic_descriptors(type, descriptor, options).each do |descriptor|   
        decorated_descriptor = descriptor.decorate(self, options)
        yield decorated_descriptor if decorated_descriptor.available?
      end
    end
    
    def filtered_semantic_descriptors(type, descriptor, options)
      descriptors = self.class.send("#{type}_#{descriptor}_descriptors")
      names, select = filter_names(options)
      method = select ? :select : :reject

      names ? descriptors.send(method) { |descriptor| names.include?(descriptor.name) } : descriptors
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
      raise ArgumentError, "options must be nil or a hash. Received '#{options.inspect}'." unless options.is_a?(Hash)
      options.slice(*known_options)
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
        def crichton_state_method(target)
          @crichton_state_method ||= if target.respond_to?(:state)
            :state
          else
            raise(Error, "No state method has been defined in the class '#{self.name}'. Please specify a " <<
              "state method using the class method #state_method or define an instance method #state on the class.")
          end
        end
      end
      
      def crichton_state
        @crichton_state ||= begin
          state_method = self.class.send(:crichton_state_method, self)
          state = @target.is_a?(Hash) ? target_state(state_method) : instance_state(state_method)
          
          state.tap do |state|
            unless [String, Symbol].include?(state.class)
              raise(Error, "The state method '#{state_method }' must return a string or a symbol. " <<
                "Returned #{state.inspect}.") 
            end
          end
        end
      end
      
    private
      def instance_state(state_method)
        send(state_method) || raise(Error, "The state was nil in the class '#{self.class.name}'. Please check " <<
          "the class properly implements a response associated with the state method '#{state_method}.'")
      end
      
      def target_state(state_method)
        unless state_key = @target.keys.detect { |k| k.to_s == state_method }
          raise(Error, "No attribute exists in the target #{@target.inspect} that corresponds to the state method" <<
            "#{state_method}.")
        end
        @target[state_key]
      end
    end
    
    ##
    # Raised in Crichton::Representors that are not configured correctly in some way.
    class Error < StandardError; end
  end
end
