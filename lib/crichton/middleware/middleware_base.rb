module Crichton
  module Middleware
    class MiddlewareBase

      #
      # get the first supported media type from the HTTP_ACCEPT list of media types in the request header
      def supported_media_type(supported_media_types, env)
        accepted_media_types(env).detect { |media_type| supported_media_types.include?(media_type) }
      end

      # generate an array of acceptable media types from the HTTP_ACCEPT header
      def accepted_media_types(env)
        env["HTTP_ACCEPT"].to_s.split(/\s*,\s*/)
      end

      # returning 406 response for requests with unsupported media types in the HTTP_ACCEPT header entry
      def unsupported_media_type(supported_media_types, env)
        error_response(406,
          "Not Acceptable media type: #{env["HTTP_ACCEPT"]}, supported types are: #{supported_media_types.join(', ')}")
      end

      def error_response(response_code, response_body)
        [response_code, {'Content-Type' => 'text/html'}, [response_body]]
      end
    end
  end
end
