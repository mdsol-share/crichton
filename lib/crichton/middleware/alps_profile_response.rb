require 'crichton/middleware/middleware_base'
require 'addressable/uri'
require 'addressable/template'
require 'crichton/helpers'

module Crichton
  module Middleware
    ##
    # Class to handle ALPS path requests ('/alps/<profile_id>') to all hypermedia based services. When the ALPS path
    # is requested, this class, deployed as rack middleware, will return the ALPS profile associated with the
    # resource. It responds with an appropriate media type with respect to the HTTP_ACCEPT environmental variable,
    # coming from the request header.
    #
    # Setup as rack middleware in config/application.rb, with an option timeout set
    # @example
    #   config.middleware.use Crichton::Middleware::AlpsProfileResponse, {'expiry' => 20}
    #
    # can be accessed using curl, with any of the supported media types below
    # @example
    #   curl --header 'Accept: application/alps+xml' localhost:3000/alps/DRDs
    #
    class AlpsProfileResponse < MiddlewareBase
      include Crichton::Helpers::ConfigHelper

      SUPPORTED_MEDIA_TYPES=%w(text/html application/alps+xml application/alps+json) # text/html for browsers

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
        # unless an alps path request, delegate to app
        if resource = alps_request(req.url)
          process_alps_response(resource['id'].first, env)
        elsif req.url == config.alps_base_uri
          # captures the "localhost:3000/alps" request
          error_response(404, "Profile not found")
        else
          @app.call(env)
        end
      end

      ##
      #
      # returns a hash with a key containing the profile id of the resource or nil
      #
      # @param [String] full_uri the complete uri of the request
      def alps_request(full_uri)
        uri = Addressable::URI.parse(full_uri.partition('#').first)
        alps_uri = Addressable::URI.parse(config.alps_base_uri)
        alps_uri.scheme = uri.scheme
        template = Addressable::Template.new("#{alps_uri}{/id*}")
        template.extract(uri)
      end

     # test for apprropriate HTTP_ACCEPT content type and processes accordngly
      def process_alps_response(profile_id, env)
        if media_type = supported_media_type(SUPPORTED_MEDIA_TYPES, env)
          send_alps_response_for_id(profile_id, media_type)
        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end

      ##
      #
      # send alps document response if resource found, else return 404 message
      #
      # @param [String] profile_id stringified id of the profile
      # @param [String] media_type the accepted content type for this request/response
      def send_alps_response_for_id(profile_id, media_type)
        if alps_document = Crichton.raw_profile_registry[profile_id]
          body = media_type == 'application/alps+json' ? alps_document.to_json : alps_document.to_xml
          return_content_type = media_type  == 'text/html' ? 'application/xml' : media_type
          [200,  {'Content-Type' => "#{return_content_type}", 'expires' => "#{(Time.new + @expiry).httpdate}"}, [body]]
        else
          error_response(404, "Profile #{profile_id} not found".split.join(' '))
        end
      end
    end
  end
end
