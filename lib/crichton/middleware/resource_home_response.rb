require 'crichton/middleware/middleware_base'
require 'crichton/discovery/entry_points'

module Crichton
  module Middleware
    ##
    # Class to handle root path requests to all hypermedia based services. When root is requested, this class,
    # deployed as rack middleware, will return a listing of all resources and their entry point urls in the service.
    # It responds with an appropriate media type with respect to the ACCEPT_HEADER environmental variable, coming
    # from the request header.
    #
    # Setup as rack middleware in config/application.rb, with an option timeout set
    # @example
    #   config.middleware.use Crichton::Middleware::ResourceHomeResponse, {'expiry' => 20}
    #
    # can be accessed using curl, with any of the supported media types below
    # @example
    #   curl --header 'Accepts: application/xhtml+xml' localhost:3000/
    #
    class ResourceHomeResponse < MiddlewareBase
      SUPPORTED_MEDIA_TYPES = %w(application/vnd.hale+json application/hal+json application/json text/html application/xhtml+xml application/xml */*)

      ##
      #
      # @param [Object] app parent framework application to this middleware rack app
      # @param [Hash] options stringified or symbolized 'expiry' options, expressed in minutes, to expire the response
      def initialize(app, options = {})
        @app = app
        # in minutes
        @expiry = (options['expiry'] || options[:expiry] || 10) * 60
      end

      ##
      #
      # standard call method for rack applications
      #
      # @param [Hash] env environmental variables for requests coming into the middleware
      def call(env)
        req = Rack::Request.new(env)

        # unless a root path request, delegate to app
        req.path == '/' ? process_home_response(env) : @app.call(env)
      end

      # Generate data and return in the appropriate Content-Type
      def process_home_response(env)
        media_type = supported_media_type(SUPPORTED_MEDIA_TYPES, env)

        if content_type_sym = response_media_type_sym(media_type)
          home_response(media_type, content_type_sym)
        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end

      ##
      #
      # return symbol of :html, :xhtml, :json or nil based on supplied media_type
      #
      # @param [String] media_type textual content_type found in http header
      def response_media_type_sym(media_type)
        case media_type
        when 'application/vnd.hale+json', 'application/hal+json', 'application/json', '*/*'
          :hale_json
        when 'text/html'
          :html
        when 'application/xhtml+xml', 'application/xml'
          :xhtml
        end
      end

      ##
      #
      # generate home response to client
      #
      # @param [String] return_content_type Content type to set in the response to the request
      # @param [Symbol] media_type :html or :xhtml to generate document response
      def home_response(return_content_type, media_type)
        [200, {'Content-Type' => "#{return_content_type}", 'expires' => "#{(Time.now + @expiry).httpdate}"},
          [Crichton::Discovery::EntryPoints.new(Crichton.entry_points).to_media_type(media_type)]]
      end
    end
  end
end
