module Crichton
  module Descriptors
    class Semantic < Base
      ##
      # A sample value for the descriptor.
      #
      # @return [Object] The sample value.
      def sample
        descriptor_document['sample']
      end

      ##
      # The type of the descriptor.
      #
      # @return [String] The type.
      def type
        'semantic'
      end
    end
  end
end
