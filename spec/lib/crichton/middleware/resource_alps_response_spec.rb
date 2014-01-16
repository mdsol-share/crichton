require 'spec_helper'
require 'crichton/middleware/resource_alps_response'
require 'crichton/helpers'

module Crichton
  module Middleware
    describe ResourceAlpsResponse do
      include Crichton::Helpers::ConfigHelper

      let (:rack_app) { double('rack_app') }

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        copy_resource_to_config_dir('api_descriptors', 'fixtures/resource_descriptors')
        FileUtils.rm_rf('api_descriptors/leviathans_descriptor_v1.yaml')
        Support::ALPSSchema::StubUrls.each do |url, body|
          stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
        end
      end

      after do
        FileUtils.rm_rf('api_descriptors')
      end

      describe '#call' do
        let(:env) { {'REQUEST_URI' => "#{config.alps_base_uri}/DRDs", 'HTTP_ACCEPT' => @media_type} }
        let(:headers) { {'Content-Type' => @media_type, 'expires' => @expires} }
        let(:home_responder) { ResourceAlpsResponse.new(rack_app) }
        let(:ten_minutes) { 600 }

        context 'when the alps path' do
          %w(text/html application/alps+xml application/alps+json).each do |media_type|
            it "responds with an alps document associated with the resource id for #{media_type} requests" do
              @media_type = media_type
              @expires = (Time.new + ten_minutes).httpdate
              home_responder.call(env).should == [200, headers, [alps_drds_document]]
            end
          end

          it 'uses the first supported media type in the HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type,*/a,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*'
            first_content_type_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            home_responder.call(env).should == [200, first_content_type_header, [alps_drds_document]]
          end

          it 'responds correctly with a non standard HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type, text/html,  application/xhtml+xml, application/xml;q=0.9,  image/webp, */*'
            first_content_type_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            home_responder.call(env).should == [200, first_content_type_header, [alps_drds_document]]
          end

          %w(text/html application/alps+xml application/alps+json).each do |media_type|
            it "responds with the expected content-type for #{media_type} requests" do
              @media_type = media_type
              response = home_responder.call(env)
              response[1]['Content-Type'].should == media_type
            end
          end

          it 'responds with the correct expiration date when it a timeout  is specified as an option' do
            responder = ResourceAlpsResponse.new(rack_app, {'expiry' => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            responder.call(env).should == [200, headers, [alps_drds_document]]
          end

          it 'responds with the correct expiration date when a symbolized timeout in specified' do
            responder = ResourceAlpsResponse.new(rack_app, {:expiry => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            responder.call(env).should == [200, headers, [alps_drds_document]]
          end

          it 'returns a 406 status for unsupported media_types' do
            @media_type = 'application/jrd+json'
            content_type_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            home_responder.call(env)[0].should == 406
          end

          it 'returns a 406 status for an empty list of acceptable media types' do
            @media_type = ''
            home_responder.call(env)[0].should == 406
          end

          it 'returns a 404 if the resource in the request is not valid' do
            @media_type = 'text/html'
            response_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            response = home_responder.call({'REQUEST_URI' => "#{config.alps_base_uri}/BLAH",
              'HTTP_ACCEPT' => @media_type})
            response.should == [404, response_header, ["Resource BLAH not found"]]
          end

          it 'returns a 404 if the alps request contains no resource' do
            @media_type = 'text/html'
            response_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            response = home_responder.call({'REQUEST_URI' => "#{config.alps_base_uri}",
              'HTTP_ACCEPT' => @media_type})
            response.should == [404, response_header, ["Resource  not found"]]
          end
        end

        context 'when not an alps path' do
          it 'invokes the parent rack app from the middleware' do
            @media_type = 'text/html'
            env = {'REQUEST_URI' => "#{config.deployment_base_uri}/drds", 'HTTP_ACCEPT' => @media_type}
            rack_app.should_receive(:call).with(env)
            home_responder.call(env)
          end
        end
      end
    end
  end
end

