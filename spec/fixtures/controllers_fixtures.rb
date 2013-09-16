require 'action_controller'
class TestController < ActionController::Base
  respond_to :xhtml
  def show(model)
    respond_with(model)
  end
end
