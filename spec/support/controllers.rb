require 'action_controller'
module Support
  module Controllers
    class TestController < ActionController::Base
      respond_to :html, :sample_type

      def show(model)
        respond_with(model)
      end

      def create(model)
        respond_with(model, status: :created, location: 'show')
      end

      def update(model)
        respond_with(model, status: :ok, location: 'show')
      end

      def destroy(model)
        head :no_content
      end
    end
  end
end

