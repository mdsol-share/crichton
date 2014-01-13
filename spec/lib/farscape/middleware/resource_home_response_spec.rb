require 'spec_helper'
require 'farscape/middleware/resource_home_response'

module Farscape
  module Middleware
    describe ResourceHomeResponse do
      let (:html_output_content) do
        # TODO PUT THIS INTO a NEW fixtures/farscape/middleware FOLDER
        ["<!DOCTYPE html>\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n  <head>\n    <link rel=\"stylesheet\" href=\"http://example.org/resources/css.css\"/>\n    <style>\n*[itemprop]::before {\n  content: attr(itemprop) \": \";\n  text-transform: capitalize;\n}\n    </style>\n  </head>\n  <body>\n    <ul>\n      <li>\n        <p/>\n        <b>Rel: </b>\n        <a rel=\"http://alps.example.org/DRDs/#list\" href=\"http://alps.example.org/DRDs/#list\">http://alps.example.org/DRDs/#list</a>\n        <b>  Url:  </b>\n        <a rel=\"http://deployment.example.org/drds\" href=\"http://deployment.example.org/drds\">http://deployment.example.org/drds</a>\n      </li>\n    </ul>\n  </body>\n</html>\n"]
      end
      let (:xml_output_content) do
        ["<!DOCTYPE html>\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n  <head>\n    <link rel=\"stylesheet\" href=\"http://example.org/resources/css.css\"/>\n    <style>\n*[itemprop]::before {\n  content: attr(itemprop) \": \";\n  text-transform: capitalize;\n}\n    </style>\n  </head>\n  <body>\n    <p/>\n    <b>Rel: </b>\n    <a rel=\"http://alps.example.org/DRDs/#list\" href=\"http://alps.example.org/DRDs/#list\">http://alps.example.org/DRDs/#list</a>\n    <b>  Url:  </b>\n    <a rel=\"http://deployment.example.org/drds\" href=\"http://deployment.example.org/drds\">http://deployment.example.org/drds</a>\n  </body>\n</html>\n"]
      end
      let (:phony_class) do
        Class.new do
          def call(env)
            [200, {'Content-Type' => 'text/html'}, 'Hello World']
          end
        end
      end
      let (:app) { phony_class.new }

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

      context 'responds to requests' do
        it 'from a browser' do
          environment = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => 'text/html'}
          home_responder = ResourceHomeResponse.new(app)
          response_should_match_expectation(home_responder.call(environment), "text/html", html_output_content)
        end

        it 'using the first supported media type found' do
          environment = {'PATH_INFO' => '/', 'HTTP_ACCEPT' =>
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'}
          home_responder = ResourceHomeResponse.new(app)
          response_should_match_expectation(home_responder.call(environment), "text/html", html_output_content)
        end
      end

      it 'returning the expected content-type for specific xml requests' do
        home_responder = ResourceHomeResponse.new(app)
        %w(application/xhtml+xml application/xml).each do |media_type|
          response = home_responder.call({'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type})
          response[1]['Content-Type'].should == 'application/xhtml+xml'
        end
      end

      it 'returning the expected content-type for specific json requests' do
        home_responder = ResourceHomeResponse.new(app)
        %w(application/json-home application/json).each do |media_type|
          response = home_responder.call({'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type})
          response[1]['Content-Type'].should == media_type
        end
      end

      it 'returning xml output for xml content type requests' do
        %w(application/xhtml+xml application/xml).each do |media_type|
          environment = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type}
          home_responder = ResourceHomeResponse.new(app)
          response_should_match_expectation(home_responder.call(environment), "application/xhtml+xml", xml_output_content)
        end
      end

      it 'returning xml output for json content type requests' do
        %w(application/json-home application/json).each do |media_type|
          environment = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => media_type}
          home_responder = ResourceHomeResponse.new(app)
          response_should_match_expectation(home_responder.call(environment), media_type, xml_output_content)
        end
      end

      it 'returning a 406 for unsupported media_types' do
        environment = {'PATH_INFO' => '/', 'HTTP_ACCEPT' => 'application/jrd+json'}
        home_responder = ResourceHomeResponse.new(app)
        response = home_responder.call(environment)
        response[0].should == 406
      end

      it 'invoking the parent application from the middleware when the request is not root' do
        home_responder = ResourceHomeResponse.new(app)
        home_responder.call({'PATH_INFO' => '/drds', 'HTTP_ACCEPT' => 'text/html'}).should ==
          [200, {'Content-Type' => 'text/html'}, 'Hello World']
      end

      def response_should_match_expectation(response, content_type, content)
        response[0].should == 200 &&
          should_have_expected_content_type(response[1], content_type) &&
          response[2].should == content
      end

      def should_have_expected_content_type(resp, content_type)
        resp["Content-Type"].should == content_type
      end
    end
  end
end
