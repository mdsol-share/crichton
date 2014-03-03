require 'spec_helper'
require 'crichton/middleware/alps_profile_response'
require 'crichton/helpers'
require 'json_spec'

module Crichton
  module Middleware
    describe AlpsProfileResponse do
      include Crichton::Helpers::ConfigHelper

      let (:rack_app) { ->(e) { [202, e, {}] } }

      before do
        Time.stub!(:new).and_return(Time.parse("Thu, 23 Jan 2014 18:00:00 GMT") )
        stub_example_configuration
        stub_configured_profiles
        stub_alps_requests
        register_drds_descriptor
      end

      after do
        clear_configured_profiles
      end
      
      shared_examples "any_scheme" do 
        let(:response_type) { @media_type == 'text/html' ? 'application/xml' : @media_type}
        let(:headers) { {'Content-Type' => response_type, 'expires' => @expires} }
        let(:home_responder) { AlpsProfileResponse.new(rack_app) }
        let(:response) { home_responder.call(env) }
        let(:rack_response) { Rack::MockResponse.new(*response) }
        let(:ten_minutes) { 600 }
        
        let(:env) do
            Rack::MockRequest.env_for(@uri).tap { |e| e["HTTP_ACCEPT"] = @media_type }
        end
        
        context 'when the alps path' do
          %w(text/html application/alps+xml).each do |media_type|
            it "responds with an alps document associated with the profile id for #{media_type} requests" do
              @media_type = media_type
              @expires =  (Time.new + ten_minutes).httpdate
              @uri = "#{base_uri}/DRDs"
              response.should == [200, headers, [alps_xml_data]]
            end
          end

          it 'responds with an alps document associated with the profile id for application/alps+json requests' do
            @media_type = 'application/alps+json'
            @expires =  (Time.new + ten_minutes).httpdate
            @uri = "#{base_uri}/DRDs"
            # go get the body of the response and JSON parse it.
            obj = JSON.parse(rack_response.body)
            body = JSON.pretty_generate(obj)
            body.should be_json_eql(alps_json_data)
          end

          it 'uses the first supported media type in the HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type,*/a,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*'
            @uri = "#{base_uri}/DRDs"
            first_content_type_header = {'Content-Type' => 'application/xml',
              'expires' => (Time.new + ten_minutes).httpdate}
            response.should == [200, first_content_type_header, [alps_xml_data]]
          end

          it 'responds correctly with a non standard HTTP_ACCEPT header' do
            @media_type = 'bogus/media_type, text/html,  application/xhtml+xml, application/xml;q=0.9,  image/webp, */*'
            @uri = "#{base_uri}/DRDs"
            first_content_type_header = {'Content-Type' => 'application/xml',
              'expires' => (Time.new + ten_minutes).httpdate}
            response.should == [200, first_content_type_header, [alps_xml_data]]
          end

          %w(text/html application/alps+xml application/alps+json).each do |media_type|
            it "responds with the expected content-type for #{media_type} requests" do
              @media_type = media_type
              @uri = "#{base_uri}/DRDs"
              media_type = 'application/xml' if media_type == 'text/html'
              rack_response.headers['Content-Type'].should == media_type
            end
          end

          it 'responds with the correct expiration date when it a timeout is specified as an option' do
            responder = AlpsProfileResponse.new(rack_app, {'expiry' => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            @uri = "#{base_uri}/DRDs"
            responder.call(env).should == [200, headers, [alps_xml_data]]
          end

          it 'responds with the correct expiration date when a symbolized timeout in specified' do
            responder = AlpsProfileResponse.new(rack_app, {:expiry => 20}) #minutes instead of default of 10
            @media_type = 'text/html'
            @expires = (Time.new + 1200).httpdate
            @uri = "#{base_uri}/DRDs"
            responder.call(env).should == [200, headers, [alps_xml_data]]
          end

          it 'returns a 406 status for unsupported media_types' do
            @media_type = 'application/jrd+json'
            @uri = "#{base_uri}/DRDs"
            rack_response.status.should == 406
          end

          it 'returns a 406 status for an empty list of acceptable media types' do
            @media_type = ''
            @uri = "#{base_uri}/DRDs"
            rack_response.status.should == 406
          end

          it 'returns a 404 if the profile in the request is not valid' do
            @media_type = 'text/html'
            @uri = "#{base_uri}/BLAH"
            response.should == [404, {'Content-Type' => 'text/html'}, ["Profile BLAH not found"]]
          end

          it 'returns a list of links if the alps xml request contains no resource' do
            @media_type = 'text/html'
            @uri = "#{base_uri}"
            body = Hash.from_xml(home_responder.call(env)[2].first)
            body['alps']['link']['href'].should == "#{base_uri}/DRDs"
          end

          it 'returns a list of links if the alps json request contains no resource' do
            @media_type = 'application/alps+json'
            @uri = "#{base_uri}"
            body = JSON.parse(home_responder.call(env)[2].first)
            body['alps']['link']['href'].should == "#{base_uri}/DRDs"
          end

          it 'successfully responds to various alps paths' do
            @media_type = 'text/html'
            @expires =  (Time.new + ten_minutes).httpdate
            %w(DRDs DRDs/ DRDs#list).each do |path_segment|
              @uri =  "#{config.alps_base_uri}/#{path_segment}"
              response.should == [200, headers, [alps_xml_data]]
            end
          end
          
          it 'invokes the parent rack app from the middleware' do
            @media_type = 'text/html'
            @uri = "some.other.url/DRDs"
            rack_response.status.should == 202
          end
        end
      end
      
      describe '#call' do
        context 'when the request scheme is HTTP' do
          let(:base_uri) { "#{config.alps_base_uri}" }
          it_behaves_like "any_scheme"
        end

        context 'when the request scheme is TCP' do
          let(:base_uri) { "tcp://alps.example.org" }
          it_behaves_like "any_scheme"
        end
      end
    end
  end
end
