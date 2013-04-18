require 'crichton/descriptor/profile'

module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @!macro string_reader
      descriptor_reader :href

      ##
      # Returns the protocol-specific descriptor of the transition.
      #
      # @param [String, Symbol] protocol The protocol.
      #
      # @return [Object] The protocol descriptor instance.
      def protocol_descriptor(protocol)
        return {} if semantic?
        
        protocol_key = protocol.downcase.to_s
        @descriptors[:protocol] ||= {}
        @descriptors[:protocol][protocol_key] ||= resource_descriptor.protocol_transition(protocol_key, id)
      end

      # @!macro string_reader
      descriptor_reader :rt
  
      # @!macro object_reader
      descriptor_reader :sample
      
      # @!macro string_reader
      descriptor_reader :type
    end
  end
end
