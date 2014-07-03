require 'spec_helper'
require 'crichton/middleware/resource_home_response'

module Crichton
  module Middleware
    describe ResourceHomeResponse do

      let (:rack_app) { double('rack_app') }

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        stub_configured_profiles
        stub_alps_requests
        register_drds_descriptor
        Timecop.freeze(Time.now)
      end

      after do
        clear_configured_profiles
        Timecop.return
      end

      describe '#call' do

        def get_response(accept_media_types)
          env = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => accept_media_types}
          ResourceHomeResponse.new(rack_app).call(env)
        end

        def get_rack_response(accept_media_types)
          Rack::MockResponse.new(*get_response(accept_media_types))
        end

        context 'when the root' do

          it 'uses the first supported media type in the HTTP_ACCEPT header' do
            headers = {'Content-Type' => 'application/vnd.hale+json', 'expires' => (Time.now + 10.minutes).httpdate}
            response = get_rack_response('bogus/media_type,*/a,application/vnd.hale+json,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*')
            expect(response.status).to eq 200
            headers["Content-Length"] = response.body.length.to_s
            expect(response.headers).to eq headers
            expect(response.body).to_not be_empty
          end

          it 'responds correctly with a non standard HTTP_ACCEPT header' do
            headers = {'Content-Type' => 'application/vnd.hale+json', 'expires' => (Time.now + 10.minutes).httpdate}
            response = get_rack_response('bogus/media_type, application/vnd.hale+json,  text/html,  application/xhtml+xml, application/xml;q=0.9,  image/webp, */*')
            expect(response.status).to eq 200
            headers["Content-Length"] = response.body.length.to_s
            expect(response.headers).to eq headers
            expect(response.body).to_not be_empty
          end

          it 'returns a 406 status for unsupported media_types' do
            response = get_rack_response('application/jrd+json')
            expect(response.status).to eq(406)
          end

          it 'returns a 406 status for an empty list of acceptable media types' do
            response = get_rack_response('')
            expect(response.status).to eq(406)
          end

          shared_examples_for "it returns the correct content_type header" do |media_type_s|
            it "responds with the expected content-type" do
              response = get_rack_response(media_type_s)
              expect(response.headers['Content-Type']).to eq(media_type_s)
            end
          end

          shared_examples_for "a jsony producer" do |media_type_s|

            it_behaves_like "it returns the correct content_type header", media_type_s

            describe "#{media_type_s} response" do
              it "produces parsable json" do
                expect do
                  parse_json(get_rack_response(media_type_s).body)
                end.to_not raise_error
              end
            end
          end

          it_behaves_like "a jsony producer", "application/vnd.hale+json"
          it_behaves_like "a jsony producer", "application/hal+json"
          it_behaves_like "a jsony producer", "application/json"

          shared_examples_for "a xmly producer" do |media_type_s|
            describe "#{media_type_s} support" do

              it_behaves_like "it returns the correct content_type header", media_type_s

              it "produces parsable XML" do
                expect do
                  REXML::Document.new(get_rack_response(media_type_s).body)
                end.to_not raise_error
              end
            end
          end

          it_behaves_like "a xmly producer", "text/html"
          it_behaves_like "a xmly producer", "application/xhtml+xml"

          describe "setting expiry" do

            let(:media_type) {'application/vnd.hale+json'}

            let(:twenty_minutes_httpdate){ (Time.now + 20.minutes).httpdate }

            it 'responds with the correct expiration date when using a string to specify the option' do
              responder = ResourceHomeResponse.new(rack_app, {'expiry' => 20}) #minutes instead of default of 10
              env = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type}
              response = Rack::MockResponse.new(*responder.call(env))
              expect(response.headers["expires"]).to eq twenty_minutes_httpdate
            end

            it 'responds with the correct expiration date when using a symbol to specify the option' do
              responder = ResourceHomeResponse.new(rack_app, {:expiry => 20}) #minutes instead of default of 10
              env = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type}
              response = Rack::MockResponse.new(*responder.call(env))
              expect(response.headers["expires"]).to eq twenty_minutes_httpdate
            end
          end
        end

        context 'when not the root' do
          it 'invokes the parent rack app from the middleware' do
            env = {'PATH_INFO' => '/drds', 'HTTP_ACCEPT' => 'application/vnd.hale+json'}
            expect(rack_app).to receive(:call).with(env)
            ResourceHomeResponse.new(rack_app).call(env)
          end
        end
      end
    end
  end
end
