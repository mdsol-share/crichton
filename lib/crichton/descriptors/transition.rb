require 'crichton/descriptors/nested'

module Crichton
  ##
  # Manages state transition information associated with resource descriptors.
  class TransitionDescriptor < Descriptor

    ##
    # Constructs a new instance of TransitionDescriptor.
    #
    # @param [Hash] resource_descriptor The parent resource descriptor instance.                                                              # 
    # @param [Hash] descriptor_document The section of the descriptor document representing this instance.
    # @param [Hash] options Optional arguments.
    # @option options [Symbol] :id Set or override the id of the descriptor.
    def initialize(resource_descriptor, descriptor_document, options = {})
      super
      @protocol_descriptors = {}
    end
    
    ##
    # Returns the protocol-specific descriptor of the transition.
    #
    # @param [String, Symbol] protocol The protocol.
    #
    # @return [Object] The protocol descriptor instance.
    def protocol_descriptor(protocol)
      protocol_key = protocol.downcase.to_s
      @protocol_descriptors[protocol_key] ||= resource_descriptor.protocol_transition(protocol_key, id)
    end
    
    ##
    # The return value of the descriptor.
    #
    # @return [String] The return value reference.
    def rt
      descriptor_document['rt']
    end

    ##
    # The type of the descriptor.
    #
    # @return [String] The type.
    def type
      descriptor_document['type']
    end
  end
end
