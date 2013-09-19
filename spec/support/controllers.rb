require 'action_controller'
module Support
  module Controllers
    class TestController < ActionController::Base
      respond_to :html, :sample_type
      def show(model)
        respond_with(model)
      end
    end
  end
end