module Crichton
  module Descriptors
    class Transition < Base
      
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
end
