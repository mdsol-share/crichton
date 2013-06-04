require 'crichton/descriptor/detail'
require 'crichton/representor'

module Crichton
  module Descriptor
    ##
    # Manages retrieving the transitions associated with transition descriptors from a target object.
    class TransitionDecorator < Detail
      
      ##
      # @param [Hash, Object] target The target instance to generate transitions from.
      # @param [Crichton::Descriptor::Detail] descriptor The Detail descriptor associated with the semantic data.
      # @param [Hash] options Optional conditions.
      # @option options [String, Symbol, Array] :conditions The state conditions.
      # @option options [String, Symbol] :protocol The protocol the transition implements.
      # @option options [String, Symbol] :state The state of the resource.
      def initialize(target, descriptor, options = {})
        super(descriptor.resource_descriptor, descriptor.parent_descriptor, descriptor.id, descriptor.descriptor_document)
        @target = target
        @options = options || {}
      end
      
      ##
      # Whether the transition is available for inclusion in a response. 
      #
      # A transition is not available if it is not defined for a particular state or if the conditions are not
      # met for the transition.
      # 
      # @return [Boolean] <tt>true</tt> if available, <tt>false</tt> otherwise.
      def available?
        state_transition ? state_transition.available?(@options.slice(:conditions)) : state.nil?
      end
      
      ##
      # Returns the uniform interface method associated with the protocol descriptor.
      def method
        protocol_descriptor && protocol_descriptor.method
      end
      
      ##
      # Returns the protocol for the transition.
      #
      # @return [String] The down-cased name of the protocol.
      def protocol
        @protocol ||= begin
          if protocol = @options[:protocol]
            protocol.to_s.downcase.tap do |protocol|
              unless resource_descriptor.protocol_exists?(protocol)
                raise "Unknown protocol #{protocol} defined by options. Available protocols are " <<
                  "#{resource_descriptor.available_protocols}."
              end
            end
          else
            resource_descriptor.default_protocol
          end
        end
      end

      ##
      # Returns the protocol-specific descriptor of the transition.
      #
      # @return [Object] The protocol descriptor instance.
      def protocol_descriptor
        @descriptors[:protocol] ||= {}
        @descriptors[:protocol][protocol] ||= resource_descriptor.protocol_transition(protocol, id)
      end
      
      ##
      # Whether the transition contains any nested semantics associated with a templated URL or a control.
      def templated?
        semantics.any?
      end
      
      def templated_url
        @templated_url ||=  url << (semantics.any? ? "{?#{semantics.values.map(&:name).join(',')}}" : '')
      end
      
      ##
      # The fully-qualified URL for the transition.
      def url
        @url ||= if protocol_descriptor
          protocol_descriptor.url_for(@target)
        else
          #TODO: log warning no url
        end
      end

    private
      def state
        @state ||= if @options[:state]
          @options[:state]
        elsif @target.is_a?(Crichton::Representor::State)
          @target.crichton_state
        else
          # TODO: Log warning no state specified
        end
      end

      def state_descriptor
        @state_descriptor ||= if state
          # TODO: Log warning if no state descriptor exists for the state, or should this raise?
          resource_descriptor.states[parent_descriptor.name][state.to_s]
        end
      end

      def state_transition
        @state_transition ||= if state
          state_descriptor.transitions[id]
        end
      end
    end
  end
end
