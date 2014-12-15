require 'spec_helper'
require 'crichton/helpers'
require 'crichton/middleware/crichton_proxy_response'

module Crichton
  module Middleware
    describe CrichtonProxyResponse do
      include Crichton::Helpers::ConfigHelper

      let (:rack_app) { double('rack_app') }

      before do
        stub_example_configuration
        register_drds_descriptor
      end

      describe '#call' do
        let(:url) { "#{config.crichton_proxy_base_uri}?url=http://example.org" }
        let(:proxy_responder) { CrichtonProxyResponse.new(rack_app) }
        let(:response) { proxy_responder.call(env) }
        let(:rack_response) { Rack::MockResponse.new(*response) }
        let(:env) do
          Rack::MockRequest.env_for(url).tap { |e| e['HTTP_ACCEPT'] = @media_type }
        end

        context 'when a crichton proxy path' do
          it 'returns a 406 status for unsupported media_types' do
            @media_type = 'text/html'
            expect(rack_response.status).to eq(406)
          end

          it 'returns a 406 status for an empty list of acceptable media types' do
            @media_type = ''
            expect(rack_response.status).to eq(406)
          end

          it 'does not yet respond to an application/json request' do
            @media_type = 'application/json'
            response = Rack::MockResponse.new(200, { 'Content-Type' => @media_type }, '')
            proxy_responder.stub_chain(:connection, :get).and_return(response)
            expect { rack_response.status }.to raise_error(NotImplementedError)
          end

          xit 'accepts media-types with different cases'
        end

        context 'when not a crichton proxy path' do
          it 'invokes the parent rack app from the middleware' do
            @media_type = 'text/html'
            env['PATH_INFO'] = '/'
            expect(rack_app).to receive(:call).with(env)
            proxy_responder.call(env)
          end
        end
      end
    end
  end
end
