require 'crichton/descriptor/profile'

module Crichton
  module Descriptor
    ##
    # Manages detail information associated with descriptors.
    class Detail < Profile
      # @!macro string_reader
      descriptor_reader :href

      # @!macro string_reader
      descriptor_reader :embed
      
      ##
      # Whether the descriptor is embeddable or not as indicated by the presence of an embed key in the
      # underlying resource descriptor document.
      #
      # @return [Boolean] <tt>true<\tt> if embeddable. <tt>false</tt> otherwise.
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
