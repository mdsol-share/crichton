require 'active_support/all'
require 'action_controller'
require 'action_dispatch'

module Support
  module Controllers
    class App
      def env_config
        {} 
      end
      
      def routes
        @routes ||= ActionDispatch::Routing::RouteSet.new.tap do |r|
          r.draw { resource :model }
        end
      end
    end

    def self.application
      @app ||= App.new
    end

    class ModelsController < ActionController::Base
      include Controllers.application.routes.url_helpers
      respond_to :html, :sample_type

      def show
        respond_with(model)
      end

      def create
        respond_with(model)
      end

      def update
        respond_with(model)
      end

      def destroy
        head :no_content
      end

      private
      def model
        # Index for spec stubbing
      end
    end
  end
end
