require 'active_support/all'
require 'action_controller'
require 'action_dispatch'
require 'active_record'

module Support
  module Controllers
    class App
      def env_config; {} end
      def routes
        return @routes if defined?(@routes)
        @routes = ActionDispatch::Routing::RouteSet.new
        @routes.draw do
          resource :model
        end
        @routes
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
        respond_with(model, location: model_url)
      end

      def destroy
        head :no_content
      end

      private
      def model
      end
    end
  end
end

