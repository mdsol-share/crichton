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
      descriptor_reader :embed
      
      ##
      # Whether the descriptor is embeddable or not as intdicated by the presesenc of an embed key in the
      # underlying resource.
      #
      # @return [Boolean] `true` if embeddable. `false` otherwise.
      def embeddable?
        !!embed
      end
      
      # @!macro string_reader
      descriptor_reader :rt

      ##
      # The source of the descriptor. Used to specify the local attribute associated with the semantic descriptor
      # name that is returned. Only set this value if the name is different than the source in the local object.
      #
      # @return [String] The source of the semantic descriptor.
      def source
        descriptor_document['source'] || name
      end
  
      # @!macro object_reader
      descriptor_reader :sample
      
      # @!macro string_reader
      descriptor_reader :type
    end
  end
end
