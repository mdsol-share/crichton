require 'addressable/uri'
require 'addressable/template'
require 'crichton/helpers'
require 'crichton/middleware/middleware_base'

module Crichton
  module Middleware
    class CrichtonProxyResponse < MiddlewareBase
      include Crichton::Helpers::ConfigHelper

      SUPPORTED_MEDIA_TYPES=%w( application/json )

      def initialize(app, options = {})
        @app = app
        @options = options
        yield connection if block_given?
      end

      def call(env)
        req = Rack::Request.new(env)
        crichton_controller_request(req) ? process_request(req, env) : @app.call(env)
      end

      private
      def crichton_controller_request(req)
        request_uri = Addressable::URI.parse(req.url.partition('?').first)
        crichton_uri = Addressable::Template.new(config.crichton_proxy_base_uri)
        crichton_uri.extract(request_uri)
      end

      def process_request(req, env)
        if supported_media_type(SUPPORTED_MEDIA_TYPES, env)
          response = connection.get do |request|
            request.url Addressable::URI.parse(req['url'])
          end
          [response.status, response.headers.to_hash.reject {|k,_| k == 'transfer-encoding' }, [response.body]]
        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end

      def connection
        @connection ||= Faraday.new do |connection|
          yield connection if block_given?
        end
      end
    end
  end
end
