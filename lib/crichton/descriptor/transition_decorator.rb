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
      
      ##
      # The fully-qualified url for the transition, including a templated query, if any, per 
      # {http://tools.ietf.org/html/rfc6570 RFC 6570}.
      # TODO: merge templated_url with url method and refactor serializers
      def templated_url
        @templated_url ||=  begin
          query = semantics.any? ? "{?#{semantics.values.map(&:name).join(',')}}" : ''
          url ? url << query : url
        end
      end
      
      ##
      # The fully-qualified URL for the transition.
      def url
        @url ||= if @options[:top_level] && @options[:override_links] && @options[:override_links][self.name]
          @options[:override_links].delete(self.name)
        else
          protocol_descriptor ? protocol_descriptor.url_for(@target) : nil
        end.tap { |url| logger.warn("The URL for the transition is not defined for #{@target.inspect}!") unless url }
      end

    private
      def state
        @state ||= if @options[:state]
          @options[:state]
        elsif @target.is_a?(Crichton::Representor::State)
          @target.crichton_state
        else
          logger.warn("No state specified for #{@target.inspect}!")
          nil
        end
      end

      def state_descriptor
        @state_descriptor ||= if state
          resource_descriptor.states[parent_descriptor.name][state.to_s].tap do |descriptor_state|
            unless descriptor_state
               raise(Crichton::MissingStateError,
                 "No state descriptor for transition #{parent_descriptor.name} -> #{state.to_s}!")
            end
          end
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
