require 'spec_helper'
require 'active_support'
require 'action_dispatch'
require 'action_controller/test_case'

describe 'testing controller' do
  before (:all) do
    Object.const_set(:Rails, RSpec::Mocks::Mock.new('Rails'))
    require 'crichton/representor'
    require 'crichton/core_ext/action_controller/responder'
    eval("class SampleTypeSerializer < Crichton::Representor::Serializer; " <<
             " media_types sample_type: %w(application/sample_media_type); " <<
         " end")
  end
  before do
    @controller = TestController.new
    @controller.request = ActionController::TestRequest.new
    @controller.response = ActionController::TestResponse.new
    @controller.request.accept = 'text/html'
    @model = double('Model')
  end
  after (:all) do
    Object.send(:remove_const, :Rails)
  end

  context 'when it is not a crichton representor model' do
    it 'should try to render html template' do
      expect { @controller.show(@model) }.to raise_error { ActionView::MissingTemplate }
    end
  end

  context 'when it is a crichton representor model' do
    it 'should call to_media_type' do
      @model.class_eval do
        include Crichton::Representor::State
      end

      @controller.request.accept = 'application/sample_media_type'
      @model.should_receive(:to_media_type).and_return(anything())
      @controller.show(@model)
    end
  end
end
