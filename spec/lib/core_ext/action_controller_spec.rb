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
    @controller.request.accept = 'application/sample_type'
    @model = double('model')
    @model.class_eval do
      include Crichton::Representor
    end
  end

  after (:all) do
    Object.send(:remove_const, :Rails)
  end

  describe '#show' do
    before do
      @controller.action_name = 'show'
    end

    context 'when it is not a crichton representor model' do
      it 'attempts to render html template and fails' do
        @controller.request.accept = 'text/html'
        expect { @controller.show(double('model')) }.to raise_error { ActionView::MissingTemplate }
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls to_media_type' do
        @model.should_receive(:to_media_type).and_return(anything())
        @controller.show(@model)
      end
    end
  end

  describe '#create' do
    before do
      @controller.action_name = 'create'
      @controller.request.request_method = 'POST'
    end

    context 'when it is not a crichton representor model' do
      it 'redirects_to #show' do
        @controller.request.accept = 'text/html'
        @controller.should_receive(:redirect_to).with('show').and_return(anything())
        @controller.create(double('model'))
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls render method with 201 status code' do
        @controller.should_receive(:render).with(hash_including(status: :created)).and_return(anything())
        @controller.create(@model)
      end

      it 'calls to_media_type' do
        @model.should_receive(:to_media_type).and_return(anything())
        @controller.create(@model)
      end
    end
  end

  describe '#update' do
    before do
      @controller.action_name = 'update'
      @controller.request.request_method = 'PUT'
    end

    context 'when it is not a crichton representor model' do
      it 'redirects_to #show' do
        @controller.request.accept = 'text/html'
        @controller.should_receive(:redirect_to).with('show').and_return(anything())
        @controller.update(double('model'))
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls render method with 200 status code' do
        @controller.should_receive(:render).with(hash_including(status: :ok)).and_return(anything())
        @controller.update(@model)
      end
    end
  end

  describe '#destroy' do
    before do
      @controller.action_name = 'destroy'
      @controller.request.request_method = 'DELETE'
    end

    it 'returns 204 status code' do
      @controller.destroy(@model)
      @controller.response.status.should equal(204)
    end
  end
end
