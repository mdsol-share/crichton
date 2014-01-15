require 'spec_helper'
require 'crichton/middleware/resource_home_response'

module Crichton
  module Middleware
    describe ResourceHomeResponse do
      let (:root_json_body) do
        {:resources => {"http://alps.example.org/DRDs/#list" => {:href => "http://deployment.example.org/drds"}}}.to_json
      end
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
        let(:env) { {'PATH_INFO' => '/', 'HTTP_ACCEPT' => @media_type} }
        let(:headers) { {'Content-Type' => @media_type, 'expires' => @expires} }
        let(:home_responder) { ResourceHomeResponse.new(rack_app) }
        let(:ten_minutes) { 600 }

        context 'when the root' do
          it 'respond to text/html' do
            @media_type = 'text/html'
            @expires = (Time.new + ten_minutes).httpdate
            home_responder.call(env).should == [200, headers, [root_html_body]]
          end

          it 'uses the first supported media type in the HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type,*/a,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*'
            first_content_type_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            home_responder.call(env).should == [200, first_content_type_header, [root_html_body]]
          end

          it 'responds correctly with a non standard HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type, text/html,  application/xhtml+xml, application/xml;q=0.9,  image/webp, */*'
            first_content_type_header = {'Content-Type' => 'text/html', 'expires' => (Time.new + ten_minutes).httpdate}
            home_responder.call(env).should == [200, first_content_type_header, [root_html_body]]
          end

          %w(application/xhtml+xml application/xml application/json-home application/json).each do |media_type|
            it "responds with the expected content-type for #{media_type} requests" do
              @media_type = media_type
              response = home_responder.call(env)
              response[1]['Content-Type'].should == media_type
            end
          end

          %w(application/xhtml+xml application/xml).each do |media_type|
            it "responds with xml output for #{media_type} content type requests" do
              @media_type = media_type
              @expires = (Time.new + ten_minutes).httpdate
              home_responder.call(env).should == [200, headers, [root_xml_body]]
            end
          end

          %w(application/json-home application/json */*).each do |media_type|
            it "responds with json-home output for #{media_type} content type requests" do
              @media_type = media_type
              @expires = (Time.new + ten_minutes).httpdate
              home_responder.call(env).should == [200, headers, [root_json_body]]
            end
          end

          it 'responds with the correct expiration date when it a timeout  is specified as an option' do
            responder = ResourceHomeResponse.new(rack_app, {'expiry' => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            responder.call(env).should == [200, headers, [root_html_body]]
          end


          it 'responds with the correct expiration date when a symbollized timeout in specified' do
            responder = ResourceHomeResponse.new(rack_app, {:expiry => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            responder.call(env).should == [200, headers, [root_html_body]]
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
        end

        context 'when not the root' do
          it 'invokes the parent rack app from the middleware' do
            @media_type = 'text/html'
            env = {'PATH_INFO' => '/drds', 'HTTP_ACCEPT' => @media_type}
            rack_app.should_receive(:call).with(env)
            home_responder.call(env)
          end
        end
      end
    end
  end
end

