module Crichton
  module Middleware
    class RegistryCleaner
      def initialize(app, options = {})
        @app = app
      end

      def call(env)
        Crichton.clear_registry if Rails.env.development?
        @app.call(env)
      end
    end
  end
end
