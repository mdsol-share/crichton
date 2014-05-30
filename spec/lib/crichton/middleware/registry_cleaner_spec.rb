require 'spec_helper'
require 'crichton/helpers'
require 'crichton/middleware/registry_cleaner'

class Rails
end

module Crichton
  module Middleware
    describe RegistryCleaner do
      include Crichton::Helpers::ConfigHelper

      before(:each) do
        @rack_app = double
        @rack_app.stub(:call)
        stub_example_configuration
        register_drds_descriptor
        stub_request(:get, /.*/)
      end

      describe '#call' do
        let(:url) { "#{config.crichton_proxy_base_uri}?url=http://example.org" }
        let(:proxy_responder) { RegistryCleaner.new(@rack_app) }
        let(:env) do
          Rack::MockRequest.env_for(url).tap { |e| e['HTTP_ACCEPT'] = @media_type }
        end
        let(:registry_value){ 'beep' }

        context 'when not in Rails development environment' do
          it 'does not try to clear the registry' do
            Rails.stub_chain(:env, :development?).and_return(false)
            Crichton.instance_variable_set(:@registry, registry_value)
            registry = Crichton.instance_variable_get(:@registry)
            proxy_responder.call(env)
            registry_after_call = Crichton.instance_variable_get(:@registry)
            expect(registry_after_call.object_id).to eql(registry.object_id)
          end
        end

        context 'when in Rails development environment' do
          it 'does clear the registry' do
            Rails.stub_chain(:env, :development?).and_return(true)
            Crichton.instance_variable_set(:@registry, registry_value)
            registry = Crichton.instance_variable_get(:@registry)
            proxy_responder.call(env)
            registry_after_call = Crichton.instance_variable_get(:@registry)
            expect(registry_after_call.object_id).to_not eql(registry.object_id)
          end
        end
      end
    end
  end
end
