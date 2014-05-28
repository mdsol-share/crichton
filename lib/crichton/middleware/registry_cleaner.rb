module Crichton
  module Middleware
    class RegistryCleaner
      def initialize(app, options = {})
        @app = app
      end

      def call(env)
        Crichton.clear_registry if Rails.env.development?
        status, headers, response = @app.call(env)
        [status, headers, response]
      end
    end
  end
end