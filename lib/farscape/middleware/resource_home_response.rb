module Farscape
  module Middleware
    class ResourceHomeResponse

      SUPPORTED_MEDIA_TYPES=%w(text/html application/xhtml+xml application/json-home application/json application/xml */*)

      def initialize(app, options = {})
        @app = app
        # in minutes
        @expiry = options['expiry'] || 10
      end

      def call(env)
        req = Rack::Request.new(env)

        media_type = get_supported_media_type(env)

        # unless a root path request, delegate to app
        if req.path == '/'
          process_home_response(media_type, env)
        else
          status, headers, body = @app.call(env)
          [status, headers, body]
        end
      end

      #
      # get the first supported media type from the HTTP_ACCEPT list of media types in the request header
      def get_supported_media_type(env)
        accepted_media_types(env).detect { |media_type| SUPPORTED_MEDIA_TYPES.include?(media_type) }
      end

      # Generate data and return in the appropriate Content-Type
      def process_home_response(media_type, env)
        case media_type
          when 'text/html'
            home_response(media_type, :html)
          when 'application/xhtml+xml', 'application/xml'
            home_response('application/xhtml+xml', :xhtml)
          when 'application/json-home', 'application/json'
            home_response(media_type, :xhtml)
          else
            unsupported_media_type(env)
        end
      end

      # generate an array of acceptable media types from the HTTP_ACCEPT header
      def accepted_media_types(env)
        env["HTTP_ACCEPT"].to_s.split(/\s*,\s*/)
      end

      # returning 406 response for requests with unsupported media types in the HTTP_ACCEPT header entry
      def unsupported_media_type(env)
        [406, {'Content-Type' => 'text/html'},
         ["Not Acceptable media type(s): #{env["HTTP_ACCEPT"]}, supported types are: #{SUPPORTED_MEDIA_TYPES.join(', ')}\n"]]
      end

      ##
      #
      # generate home response to client
      #
      # @param [String] return_content_type Content type to set in the response to the request
      # @param [Symbol] media_type :html or :xhtml to generate document response
      def home_response(return_content_type, media_type)
        [200, {'Content-Type' => "#{return_content_type}", 'expires' => "#{@expiry.minutes.from_now.httpdate}"},
         [Crichton::Discovery::EntryPoints.new(Crichton.entry_points).to_media_type(media_type)]]
      end
    end
  end
end
