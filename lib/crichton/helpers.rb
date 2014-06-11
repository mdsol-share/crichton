require 'crichton/configuration'

module Crichton
  module Helpers
    module ConfigHelper
      def config
        Crichton.config
      end

      def logger
        Crichton.logger
      end
    end
  end
end
