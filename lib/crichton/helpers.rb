require 'crichton/configuration'

module Crichton
  module Helpers
    module ConfigHelper
      def config
        @config ||= Crichton.config
      end

      def logger
        @logger ||= Crichton.logger
      end
    end

    module DescriptorKeywords
      TAG = 'descriptors'
      OPTIONS = 'options'
      PARAMETERS = 'parameters'
      EXTENSIONS = 'extensions'
      RESOURCES = 'resources'
      SEMANTIC = 'semantic'
      TYPES = %w(safe unsafe idempotent semantics)

      ID = 'id'
      DOC = 'doc'
      LINKS = 'links'
      HREF = 'href'
      EXT = 'ext'
      TYPE = 'type'
    end
  end
end
