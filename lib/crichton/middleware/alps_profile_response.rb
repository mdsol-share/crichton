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
        @expiry = (options['expiry'] || options[:expiry] || 10) * 60 # in minutes
      end

      ##
      #
      # standard call method for rack applications
      #
      # @param [Hash] env environmental variables for requests coming into the middleware
      def call(env)
        process_response(env) || @app.call(env)
      end

    private
      def process_response(env)
        alps_request = process_alps_request(env)
        
        process_alps_response(alps_request['profile_id'], env) if alps_request
      end
      
      def process_alps_request(env)
        req = Rack::Request.new(env).tap { |r| @request = r }
        uri = Addressable::URI.parse(req.url.downcase.partition('#').first).tap do |u| 
          u.path = u.path.gsub(/\/$/, '') # remove trailing slash
        end   
        extract_profile_id(uri)
      end
      
      def extract_profile_id(uri)
        alps_uri = alps_base_uri.dup.tap do |u| 
          path = u.path
          u.scheme = uri.scheme
          u.host = uri.host
          u.path = path
        end
        template = Addressable::Template.new("#{alps_uri}{/id*}")
        extracted_id = template.extract(uri)
        
        profile_id = extracted_id && extracted_id['id'].one? && extracted_id['id'].first

        {'profile_id' => profile_id} if profile_id || uri.path == alps_uri.path
      end

      def alps_base_uri
        @alps_base_uri ||= Addressable::URI.parse(config.alps_base_uri.downcase).tap do |u|
          u.path = u.path.gsub(/\/$/, '') # remove trailing slash
        end
      end

      # test for appropriate HTTP_ACCEPT content type and processes accordingly
      def process_alps_response(profile_id, env)
        if media_type = supported_media_type(SUPPORTED_MEDIA_TYPES, env)
          alps_rack_response(profile_id, media_type)
        else
          unsupported_media_type(SUPPORTED_MEDIA_TYPES, env)
        end
      end
      
      ##
      # send alps document rack response if profile found, else return 404 message
      def alps_rack_response(profile_id, media_type)
        registry_key = Crichton.raw_profile_registry.keys.detect { |k| k.downcase == profile_id }
        if alps_document = Crichton.raw_profile_registry[registry_key]
          body = media_type == 'application/alps+json' ? alps_document.to_json : alps_document.to_xml
          return_content_type = media_type  == 'text/html' ? 'application/xml' : media_type
          [200,  {'Content-Type' => "#{return_content_type}", 'expires' => "#{(Time.new + @expiry).httpdate}"}, [body]]
        else
          unless profile_id
            doc = Nokogiri::XML('<alps></alps>')
            alps_document = Crichton.raw_profile_registry.each do |k, v| 
              subalps = Nokogiri::XML(v.to_xml).xpath('/alps/link[@rel="self"]')[0]
              href = URI(subalps['href'])
              href.scheme = @request.scheme.downcase
              href.host = @request.host.downcase
              href.port = @request.port
              subalps['rel'] = k
              subalps['href'] = href.to_s
              doc.root.add_child(subalps)
            end
            body = media_type == 'application/alps+json' ? Hash.from_xml(doc.to_xml).to_json : doc.to_xml
            return_content_type = media_type  == 'text/html' ? 'application/xml' : media_type
            [200,  {'Content-Type' => "#{return_content_type}", 'expires' => "#{(Time.new + @expiry).httpdate}"}, [body]]
          else
            error_response(404, "Profile #{profile_id} not found")
          end
        end
      end
    end
  end
end
