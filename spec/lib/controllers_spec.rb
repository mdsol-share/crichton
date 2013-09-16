require 'spec_helper'
require 'active_support'
require 'action_dispatch'
require 'action_controller/test_case'

class Model
  include Crichton::Representor::State
end

describe 'test controller' do
  describe 'respond_to :xhtml' do
    before(:each) do
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      @controller = TestController.new
      @request.accept = 'application/xhtml+xml'
      @controller.request = @request
      @controller.response = @response
    end

    context 'when it is not a crichton representor model' do
      it 'should try to render xhtml template' do
        expect { @controller.show(double('Model')) }.to raise_error { ActionView::MissingTemplate }
      end
    end

    context 'when it is a crichton representor model' do
      it 'should call to_media_type' do
        p = Model.new
        p.should_receive(:to_media_type).and_return(anything())
        @controller.show(p)
      end
    end
  end
end
