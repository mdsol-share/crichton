require 'addressable/uri'
require 'addressable/template'
require 'crichton/helpers'

module Crichton
  module Middleware
    ##
    # Class to handle alps path requests ('/alps/<resource_id>') to all hypermedia based services. When the alps path
    # is requested, this class, deployed as rack middleware, will return the alps document associated with the
    # resource. It responds with an appropriate media type with respect to the ACCEPT_HEADER environmental variable,
    # coming from the request header.
    #
    # Setup as rack middleware in config/application.rb, with an option timeout set
    # @example
    #   config.middleware.use "Crichton::Middleware::ResourceAlpsResponse", {'expiry' => 20}
    #
    # can be accessed using curl, with any of the supported media types below
    # @example
    #   curl --header 'Accept: application/alps+xml' localhost:3000/alps/DRDs
    #
    class ResourceAlpsResponse
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
        # unless an alps path request, delegate to app
        if resource = alps_request(env['REQUEST_URI'])
          process_alps_response(resource['id'], env)
        elsif env['REQUEST_URI'] == config.alps_base_uri
          # captures the "localhost:3000/alps" request
          resource_not_found(nil)
        else
          @app.call(env)
        end
      end

      ##
      #
      # returns a hash with a key containing the id of the resource or nil
      #
      # @param [String] full_uri the complete uri of the request
      def alps_request(full_uri)
        uri = Addressable::URI.parse(full_uri)
        Addressable::Template.new("#{config.alps_base_uri}/{id}").extract(uri)
      end

     # test for apprropriate HTTP_ACCEPT content type and processes accordngly
      def process_alps_response(resource_id, env)
        if media_type =supported_media_type(env)
          send_alps_response_for_id(resource_id, media_type)
        else
          unsupported_media_type(env)
        end
      end

      ##
      #
      # send alps document response if resource found, else return 404 message
      #
      # @param [String] resource_id stringified id of the resource
      # @param [String] media_type the accepted content type for this request/response
      def send_alps_response_for_id(resource_id, media_type)
        if alps_document = Crichton.raw_profile_registry[resource_id]
          [200,  {'Content-Type' => "#{media_type}",
            'expires' => "#{(Time.new + @expiry).httpdate}"}, [alps_document.to_xml]]
        else
          resource_not_found(resource_id)
        end
      end

      #
      # get the first supported media type from the HTTP_ACCEPT list of media types in the request header
      def supported_media_type(env)
        accepted_media_types(env).detect { |media_type| SUPPORTED_MEDIA_TYPES.include?(media_type) }
      end

      # generate an array of acceptable media types from the HTTP_ACCEPT header
      def accepted_media_types(env)
        env["HTTP_ACCEPT"].to_s.split(/\s*,\s*/)
      end

      # returning 406 response for requests with unsupported media types in the HTTP_ACCEPT header entry
      def unsupported_media_type(env)
        [406, {'Content-Type' => 'text/html'},
         ["Not Acceptable media type: #{env["HTTP_ACCEPT"]}, supported types are: #{SUPPORTED_MEDIA_TYPES.join(', ')}"]]
      end

      def resource_not_found(resource_id)
        [404, {'Content-Type' => 'text/html',
          'expires' => "#{(Time.new + @expiry).httpdate}"}, ["Resource #{resource_id} not found"]]
      end
    end
  end
end
