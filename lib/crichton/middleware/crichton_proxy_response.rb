require 'addressable/uri'
require 'addressable/template'
require 'crichton/helpers'
require 'crichton/middleware/middleware_base'

module Crichton
  module Middleware
    class CrichtonProxyResponse < MiddlewareBase
      include Crichton::Helpers::ConfigHelper

      SUPPORTED_MEDIA_TYPES = %w(application/json)

      def initialize(app, options = {})
        @app = app
        @options = options
      end

      def call(env)
        req = Rack::Request.new(env)
        crichton_controller_request?(req) ? process_request(req, env) : @app.call(env)
      end

      private
      def crichton_controller_request?(req)
        request_uri = Addressable::URI.parse(req.url.partition('?').first)
        crichton_uri = Addressable::Template.new(config.crichton_proxy_base_uri)
        crichton_uri.extract(request_uri)
      end

      def process_request(req, env)
        if supported_media_type(SUPPORTED_MEDIA_TYPES, env)
          raise NotImplementedError, "Valid proxy requests are not implemented"
        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end
    end
  end
end
