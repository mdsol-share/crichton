require 'crichton/representor/serializer'
require "json"

module Crichton
  module Discovery

    class EntryPoint
      include Crichton::Representor
      represents :entry_point

      attr_reader :resource_relation
      attr_reader :resource_uri

      def initialize(resource_uri, resource_relation)
        @resource_relation =  resource_relation
        @resource_uri = resource_uri
      end

      # prefer to find a way to not override this
      def to_media_type(media_type)
        case media_type
          when :json_home
            @resources.to_json
          when :html
            # maybe generate a link
          else
            # super
        end
      end
    end
  end
end
