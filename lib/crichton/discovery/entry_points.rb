require 'crichton/representor/serializer'
require 'crichton/representor/serializers/json_home'
require "json"

module Crichton
  module Discovery

    class EntryPoints
      include Crichton::Representor
      represents :entry_points

      attr_reader :resources

      def initialize(resources)
        @resources = resources
      end

      # prefer to find a way to not override this
      def to_media_type(media_type)
        case media_type
          when :json_home
            serializer = JsonHomeSerializer.new(self)
            serializer.to_media_type
          when :html
            # TODO
            super
          else
            # FAIL?
            # super
        end
      end
    end
  end
end
