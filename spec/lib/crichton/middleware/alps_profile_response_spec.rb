require 'spec_helper'
require 'crichton/middleware/alps_profile_response'
require 'crichton/helpers'
require 'json_spec'

module Crichton
  module Middleware
    describe AlpsProfileResponse do
      include Crichton::Helpers::ConfigHelper

      let (:rack_app) { ->(e) { [202, e, {}] } }
      let (:resource_descriptor_hash) do
        resource_descriptor = <<-YAML
          id: DRDs
          doc: Describes the semantics, states and state transitions associated with DRDs.
          links:
            profile: DRDs
            help: DRDs#help
          semantics:
            name:
              href: http://alps.io/schema.org/Text
          idempotent:
            update:
              rt: none
              links:
                profile: DRDs#update
              parameters:
                - href: name
        YAML
        YAML.load(resource_descriptor)
      end
      let (:expected_xml_result) do
        expected_result = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <alps>
            <doc>Describes the semantics, states and state transitions associated with DRDs.</doc>
            <link rel="profile" href="http://alps.example.org/DRDs"/>
            <link rel="help" href="http://documentation.example.org/DRDs#help"/>
            <descriptor id="name" type="semantic" href="http://alps.io/schema.org/Text">
            </descriptor>
            <descriptor id="update" type="idempotent" rt="none">
              <link rel="profile" href="http://alps.example.org/DRDs#update"/>
              <descriptor href="#name"/>
            </descriptor>
          </alps>
        XML
        Nokogiri.XML(expected_result)
      end
      let (:expected_json_result) do
        expected_result = <<-HERE
        {
          "alps":{
            "doc":{"value":"Describes the semantics, states and state transitions associated with DRDs."},
            "link": [
              {"rel":"profile","href":"http://alps.example.org/DRDs"},
              {"rel":"help","href":"http://documentation.example.org/DRDs#help"}
            ],
            "descriptor":[
              {"id":"name","type":"semantic","href":"http://alps.io/schema.org/Text"},
              {
                "link": [{"rel":"profile","href":"http://alps.example.org/DRDs#update"}],
                "id":"update","type":"idempotent","rt":"none", "descriptor":[{"href":"name"}]
              }
            ]
          }
        }
        HERE
      end
      let (:registry) { Crichton::Registry.new(automatic_load: false) }

      before do
        allow(Time).to receive(:new).and_return(Time.parse('Thu, 23 Jan 2014 18:00:00 GMT') )
        stub_example_configuration
        stub_configured_profiles
        stub_alps_requests
        registry.register_single(resource_descriptor_hash)
        allow(Crichton).to receive(:raw_profile_registry).and_return(registry.raw_profile_registry)
      end

      after do
        clear_configured_profiles
      end
      
      shared_examples 'any_scheme' do        
        let(:response_type) { @media_type == 'text/html' ? 'application/xml' : @media_type}
        let(:headers) { {'Content-Type' => response_type, 'expires' => @expires} }
        let(:alps_middleware) { AlpsProfileResponse.new(rack_app) }
        let(:response) { alps_middleware.call(env) }
        let(:rack_response) { Rack::MockResponse.new(*response) }
        let(:ten_minutes) { 600 }
        let(:uri) { @uri }
        let(:base_uri) { @base_uri }
        
        let(:env) do
            Rack::MockRequest.env_for(uri).tap { |e| e["HTTP_ACCEPT"] = @media_type }
        end
        
        context 'when the alps path' do
          context 'with a profile specified' do
            before do
              @uri = "#{base_uri}/DRDs"
            end      

            shared_examples_for 'an alps document associated with the profile' do
              it_behaves_like 'a correct response status and response headers'

              it_behaves_like 'an equivalent XML'
            end

            shared_examples_for 'a correct response status and response headers' do
              it 'returns proper response status code' do
                expect(@response_status_code).to eq(@expected_status_code)
              end

              it 'returns proper response headers' do
                expect(@response_headers).to eq(@expected_headers)
              end
            end

            shared_examples_for 'an equivalent XML' do
              let (:xpath_function) { ->(selector, xml) { xml.xpath(selector).text.strip } }

              after do
                expect(xpath_function.(@selector, @response_xml)).to eq(xpath_function.(@selector, expected_xml_result))
              end

              it 'returns doc' do
                @selector = '/alps/doc'
              end

              it 'returns profile link' do
                @selector = '/alps/link[@rel="profile"]/@href'
              end

              it 'retuns help link' do
                @selector = '/alps/link[@rel="help"]/@href'
              end

              it 'returns descriptors as xml elements' do
                expect(@response_xml.xpath('/alps/descriptor').size).to eq(2)
              end

              %w(1 2).each do |index|
                it 'returns descriptor name' do
                  @selector = "/alps/descriptor#{index}/@id"
                end

                it 'returns descriptor type' do
                  @selector = "/alps/descriptor#{index}/@type"
                end

                it 'returns descriptor href' do
                  @selector = "/alps/descriptor#{index}/@href"
                end
              end

              it 'returns child link element' do
                @selector = '/alps/descriptor[2]/link[@rel="profile"]/@href'
              end

              it 'returns child descriptor element' do
                @selector = '/alps/descriptor[2]/descriptor/@href'
              end
            end

            shared_examples_for 'a case-insensitive profile' do
              %w(text/html application/alps+xml).each do |media_type|
                context "when #{media_type} requests" do
                  before do
                    @media_type = media_type
                    @expires =  (Time.new + ten_minutes).httpdate
                    @response_status_code, @response_headers, response_body = response
                    @response_xml = Nokogiri.XML(response_body.first)
                    @expected_status_code = 200
                    @expected_headers = headers
                  end

                  it_behaves_like 'an alps document associated with the profile'
                end
              end

              it 'accepts media-types with different cases' do
                @media_type = 'appLication/alps+Json'
                @expires = (Time.new + ten_minutes).httpdate
                # go get the body of the response and JSON parse it.
                expect(rack_response.body).to be_json_eql(expected_json_result)
              end

              it 'responds with an alps document associated with the profile id for application/alps+json requests' do
                @media_type = 'application/alps+json'
                @expires =  (Time.new + ten_minutes).httpdate
                # go get the body of the response and JSON parse it.
                expect(rack_response.body).to be_json_eql(expected_json_result)
              end

              context 'when non standard HTTP_ACCEPT header' do
                before do
                  @media_type = 'bogus/media_type,*/a,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*'
                  @expected_headers = { 'Content-Type' => 'application/xml',
                                        'expires' => (Time.new + ten_minutes).httpdate }
                  @response_status_code, @response_headers, response_body = response
                  @expected_status_code = 200
                end

                it_behaves_like 'a correct response status and response headers'
              end

              %w(text/html application/alps+xml application/alps+json).each do |media_type|
                it "responds with the expected content-type for #{media_type} requests" do
                  @media_type = media_type
                  media_type = 'application/xml' if media_type == 'text/html'
                  expect(rack_response.headers['Content-Type']).to eq(media_type)
                end
              end

              it 'responds with the correct expiration date when it a timeout is specified as an option' do
                responder = AlpsProfileResponse.new(rack_app, {'expiry' => 20}) #minutes instead of default of 10
                @media_type = 'text/html'
                @expires = (Time.new + 1200).httpdate
                response = responder.call(env)
                rack_response = Rack::MockResponse.new(*response)
                expect(rack_response.headers['expires']).to eq(headers['expires'])
              end

              it 'responds with the correct expiration date when a symbolized timeout in specified' do
                responder = AlpsProfileResponse.new(rack_app, {:expiry => 20}) #minutes instead of default of 10
                @media_type = 'text/html'
                @expires = (Time.new + 1200).httpdate
                response = responder.call(env)
                rack_response = Rack::MockResponse.new(*response)
                expect(rack_response.headers['expires']).to eq(headers['expires'])
              end

              it 'returns a 406 status for unsupported media_types' do
                @media_type = 'application/jrd+json'
                expect(rack_response.status).to eq(406)
              end

              it 'returns a 406 status for an empty list of acceptable media types' do
                @media_type = ''
                expect(rack_response.status).to eq(406)
              end

              %w(DRDs DRDs/ DRDs#list).each do |path_segment|
                context "when alps path segment #{path_segment}" do
                  before do
                    @media_type = 'text/html'
                    @expires = (Time.new + ten_minutes).httpdate
                    @uri = "#{base_uri}/#{path_segment}"
                    @expected_headers = headers
                    @response_status_code, @response_headers, response_body = response
                    @expected_status_code = 200
                  end

                  it_behaves_like 'a correct response status and response headers'
                end
              end

              it 'returns a 404 if the profile in the request is not valid' do
                @media_type = 'text/html'
                @uri = "#{base_uri}/BLAH"
                expect(response).to eq([404, {'Content-Type' => 'text/html'}, ["Profile blah not found."]])
              end

              context 'without a profile specified' do
                before do
                  @uri = "#{base_uri}"
                end

                it 'returns a list of links if the alps xml request contains no resource' do
                  @media_type = 'text/html'
                  body = Hash.from_xml(rack_response.body)
                  expect(body['alps']['link']['href']).to eq("#{base_uri.downcase}/DRDs")
                end

                it 'returns a list of links if the alps json request contains no resource' do
                  @media_type = 'application/alps+json'
                  body = JSON.parse(rack_response.body)
                  expect(body['alps']['link']['href']).to eq("#{base_uri.downcase}/DRDs")
                end
              end
            end

            context 'with an upper-case profile' do
              let(:uri) { @uri.upcase }
              
              it_behaves_like 'a case-insensitive profile'
            end

            context 'with an upper-case base uri' do
              let(:base_uri) { @base_uri.upcase }

              it_behaves_like 'a case-insensitive profile'
            end

            it_behaves_like 'a case-insensitive profile'

            context 'with a lower-case profile' do
              let(:uri) { @uri.downcase }

              it_behaves_like 'a case-insensitive profile'
            end

            context 'with an lower-case base uri' do
              let(:base_uri) { @base_uri.downcase }

              it_behaves_like 'a case-insensitive profile'
            end
          end
        end

        context 'when not an alps path' do
          it 'invokes the parent rack app from the middleware' do
            @media_type = 'text/html'
            @uri = "#{base_uri}/DRDs/more"
            expect(rack_app).to receive(:call).with(env)
            alps_middleware.call(env)
          end
        end
      end
      
      describe '#call' do
        context 'when the request scheme is HTTP domain' do
          before do
            @base_uri = "#{config.alps_base_uri}"
          end
          
          it_behaves_like 'any_scheme'
        end

        context 'when the request scheme is TCP' do
          before do
            @base_uri = 'tcp://123.456.789.1:5555'
          end
          
          it_behaves_like 'any_scheme'
          
          # TODO: make fixtures less brittle so this pertinent failing test can succeed.
          #context 'when alps_base_uri has a different port' do
          #  before do
          #    ::Crichton.config.stub(:alps_base_uri).and_return('http://alps.example.org:3000')
          #  end
          #
          #  it_behaves_like 'any_scheme'
          #end
        end
      end
    end
  end
end
