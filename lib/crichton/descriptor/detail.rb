module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @!macro string_reader
      descriptor_reader :href
  
      ##
      # @!attribute [r] name
      # The name of the descriptor.
      #
      # Defaults to the id of the descriptor unless a <tt>name</tt> is explicitly specified. This is necessary when
      # the associated id is modified to make it unique compared to an existing id for another descriptor.
      #
      # @return [String] The descriptor name.
      def name
        descriptor_document['name'] || id
      end

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
