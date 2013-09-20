require 'spec_helper'
require 'active_support'
require 'action_dispatch'
require 'action_controller/test_case'

describe 'ActionController' do
  before (:all) do
    Object.const_set(:Rails, RSpec::Mocks::Mock.new('Rails'))
    require 'crichton/representor'
    require 'core_ext/action_controller/responder'
    eval(build_sample_serializer(:SampleTypeSerializer))
  end

  before do
    @controller = Support::Controllers::TestController.new
    @controller.request = ActionController::TestRequest.new
    @controller.response = ActionController::TestResponse.new
    @controller.request.accept = 'text/html'
    @model = double('model')
  end

  after (:all) do
    Object.send(:remove_const, :Rails)
  end

  describe '#show' do
    context 'when it is not a crichton representor model' do
      it 'attempts to render html template and fails' do
        expect { @controller.show(@model) }.to raise_error { ActionView::MissingTemplate }
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls to_media_type' do
        @model.class_eval do
          include Crichton::Representor
        end
        @controller.request.accept = 'application/sample_type'
        @model.should_receive(:to_media_type).and_return(anything())
        @controller.show(@model)
      end
    end
  end
end
