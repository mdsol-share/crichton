module Crichton
  module Middleware
    class ResourceHomeResponse

      SUPPORTED_MEDIA_TYPES=%w(text/html application/xhtml+xml application/xml application/json-home application/json */*)

      def initialize(app, options = {})
        @app = app
        # in minutes
        @expiry = (options['expiry'] || 10) * 60
      end

      def call(env)
        req = Rack::Request.new(env)

        # unless a root path request, delegate to app
        req.path == '/' ? process_home_response(env) : @app.call(env)
      end

      #
      # get the first supported media type from the HTTP_ACCEPT list of media types in the request header
      def get_supported_media_type(env)
        accepted_media_types(env).detect { |media_type| SUPPORTED_MEDIA_TYPES.include?(media_type) }
      end

      # Generate data and return in the appropriate Content-Type
      def process_home_response(env)
        media_type = get_supported_media_type(env)

        if content_type_sym = response_media_type_sym(media_type)
          home_response(media_type, content_type_sym)
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
         ["Not Acceptable media type(s): #{env["HTTP_ACCEPT"]}, supported types are: #{SUPPORTED_MEDIA_TYPES.join(', ')}"]]
      end

      ##
      #
      # return symbol of :html, :xhtml, :json or nil based on supplied media_type
      #
      # @param [String] media_type textual content_type found in http header
      def response_media_type_sym(media_type)
        case media_type
        when 'text/html'
          :html
        when 'application/xhtml+xml', 'application/xml'
          :xhtml
        when 'application/json-home', 'application/json', '*/*'
          :json_home
        else
          nil
        end
      end

      ##
      #
      # generate home response to client
      #
      # @param [String] return_content_type Content type to set in the response to the request
      # @param [Symbol] media_type :html or :xhtml to generate document response
      def home_response(return_content_type, media_type)
        [200, {'Content-Type' => "#{return_content_type}", 'expires' => "#{(Time.new+@expiry).httpdate}"},
          [Crichton::Discovery::EntryPoints.new(Crichton.entry_points).to_media_type(media_type)]]
      end
    end
  end
end

