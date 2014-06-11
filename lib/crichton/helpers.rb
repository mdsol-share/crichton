require 'crichton/configuration'

module Crichton
  module Helpers
    module ConfigHelper
      def config
        @config = Crichton.config
      end

      def logger
        @logger = Crichton.logger
      end
    end
  end
end
