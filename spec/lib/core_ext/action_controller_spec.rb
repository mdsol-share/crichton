require 'spec_helper'
require 'active_support'
require 'action_dispatch'
require 'action_controller/test_case'

class Model
  def self.model_name
    ActiveModel::Name.new(self)
  end
end

describe 'ActionController' do
  before (:all) do
    Object.const_set(:Rails, RSpec::Mocks::Mock.new('Rails'))
    require 'crichton/representor'
    require 'core_ext/action_controller/responder'
    eval(build_sample_serializer(:SampleTypeSerializer))
  end

  before do
    @controller = Support::Controllers::ModelsController.new
    @controller.request = ActionController::TestRequest.new
    @controller.response = ActionController::TestResponse.new
    @controller.request.accept = 'application/sample_type'
    @model = Model.new
    @model.class_eval do
      include Crichton::Representor
    end
    @controller.stub(:model).and_return(@model)
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
        @controller.stub(:model).and_return(Model.new)
        expect { @controller.show }.to raise_error { ActionView::MissingTemplate }
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls to_media_type' do
        @model.should_receive(:to_media_type).with(:sample_type, anything).and_return(anything)
        @controller.show
      end
    end
  end

  describe '#create' do
    before do
      @controller.action_name = 'create'
      @controller.request.request_method = 'POST'
    end

    context 'when it is not a crichton representor model' do
      it 'returns 302 status code' do
        @controller.request.accept = 'text/html'
        @controller.stub(:model).and_return(Model.new)
        @controller.create
        @controller.response.status.should equal(302)
      end
    end

    context 'when it is a crichton representor model' do
      it 'calls to_media_type' do
        @model.should_receive(:to_media_type).with(:sample_type, anything).and_return(anything)
        @controller.create
      end
    end
  end

  describe '#update' do
    before do
      @controller.action_name = 'update'
      @controller.request.request_method = 'PUT'
    end

    context 'when it is a crichton representor model' do
      it 'calls render method with 200 status code' do
        @controller.update
        @controller.response.status.should equal(204)

      end
    end
  end

  describe '#destroy' do
    before do
      @controller.action_name = 'destroy'
      @controller.request.request_method = 'DELETE'
    end

    it 'returns 204 status code' do
      @controller.destroy
      @controller.response.status.should equal(204)
    end
  end
end
