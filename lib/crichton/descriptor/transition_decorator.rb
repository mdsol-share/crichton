require 'crichton/descriptor/detail_decorator'
require 'crichton/representor'

module Crichton
  module Descriptor
    ##
    # Manages retrieving the transitions associated with transition descriptors from a target object.
    class TransitionDecorator < DetailDecorator

      ##
      # @param [Hash, Object] target The target instance to generate transitions from.
      # @param [Crichton::Descriptor::Detail] descriptor The Detail descriptor associated with the semantic data.
      # @param [Hash] options Optional conditions.
      # @option options [String, Symbol, Array] :conditions The state conditions.
      # @option options [String, Symbol] :protocol The protocol the transition implements.
      # @option options [String, Symbol] :state The state of the resource.
      def initialize(target, descriptor, options = {})
        super
      end

      ##
      # The name of the transition.
      #
      # Defaults to the id of the descriptor unless a <tt>name</tt> is explicitly specified. This is necessary when
      # the associated id is modified to make it unique compared to an existing id for another descriptor.
      #
      # @return [String] The transition name.
      def name
        available? ? state_transition.name : super
      end

      ##
      # Whether the transition is available for inclusion in a response.
      #
      # A transition is not available if it is not defined for a particular state or if the conditions are not
      # met for the transition.
      #
      # @return [Boolean] <tt>true</tt> if available, <tt>false</tt> otherwise.
      def available?
        @available ||= state_transition ? state_transition.available?(@_options.slice(:conditions)) : state.nil?
      end

      ##
      # Returns the uniform interface method associated with the protocol descriptor.
      def interface_method
        protocol_descriptor && protocol_descriptor.interface_method
      end

      ##
      # Returns the protocol for the transition.
      #
      # @return [String] The down-cased name of the protocol.
      def protocol
        @protocol ||= begin
          if protocol = @_options[:protocol]
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
          url_params = templated? ? semantics.values.select(&:scope?) : []
          query = url_params.any? ? "{?#{url_params.map(&:name).join(',')}}" : ''
          url ? url << query : url
        end
      end

      ##
      # The fully-qualified URL for the transition.
      def url
        @url ||= if @_options[:top_level] && @_options[:override_links] && @_options[:override_links][self.name]
          @_options[:override_links].delete(self.name)
        else
          protocol_descriptor ? protocol_descriptor.url_for(@target) : nil
        end.tap { |url| logger.warn("Crichton::Descriptor::TransitionDecorator.url class (#{@target}) does not have a known url") unless url }
      end

      def response_headers
        @response_headers ||= state_descriptor.decorate(@target).to_hash
      end

    private
      def state
        @state ||= if @_options[:state]
          @_options[:state]
        elsif @target.is_a?(Crichton::Representor::State)
          @target.crichton_state
        else
          logger.warn("No state specified for #{@target}")
          nil
        end
      end

      def state_descriptor
        @state_descriptor ||= if state
          resource_descriptor.states[parent_descriptor.name][state.to_s].tap do |descriptor_state|
            unless descriptor_state
              raise(Crichton::MissingStateError,
                "No state '#{state.to_s}' defined for resource '#{parent_descriptor.name}' in API " <<
                "descriptor document with ID: #{parent_descriptor.resource_descriptor.id}")
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
