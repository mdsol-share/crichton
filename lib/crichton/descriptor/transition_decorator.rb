require 'crichton/descriptor/detail'

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
      # @option options [String, Symbol] :state The state of the object.
      def initialize(target, descriptor, options = {})
        super(descriptor.resource_descriptor, descriptor.descriptor_document)
        @target = target
        @options = options || {}
      end
      
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
      # Whether the source of the data exists in the hash or object. This is not a <tt>nil?</tt> check, but rather 
      # determines if the related attribute is defined on the object.
      #
      # @return [Boolean] true, if the data source is defined.
      def source_defined?
        @target.is_a?(Hash) ? @target.key?(source) : @target.respond_to?(source)
      end
    end
  end
end
