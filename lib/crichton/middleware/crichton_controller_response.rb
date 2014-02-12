require 'crichton/middleware/middleware_base'
require 'addressable/uri'
require 'addressable/template'
require 'crichton/helpers'

module Crichton
  module Middleware
    class CrichtonControllerResponse < MiddlewareBase
      include Crichton::Helpers::ConfigHelper

      SUPPORTED_MEDIA_TYPES=%w(text/html application/xhtml+xml application/json application/vnd.hale+json */*)

      def initialize(app, options = {})
        @app = app
      end

      def call(env)
        crichton_controller_request(env) ? process_request(env) : @app.call(env)
      end

      private
      def crichton_controller_request(env)
        req = Rack::Request.new(env)
        request_uri = Addressable::URI.parse(req.url.partition('?').first)
        crichton_uri = Addressable::Template.new(config.crichton_controller_uri)
        crichton_uri.extract(request_uri)
      end

      def process_request(env)
        if supported_media_type(SUPPORTED_MEDIA_TYPES, env)

        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end
    end
  end
end
