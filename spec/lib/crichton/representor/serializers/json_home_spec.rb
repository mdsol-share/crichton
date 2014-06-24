require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/json_home'
require 'crichton/discovery/entry_points'
require 'json_spec'

module Crichton
  module Representor
    describe JsonHomeSerializer do
      let(:deployment_base_uri) { 'http://deployment.example.org' }
      let(:apls_base_uri) { 'http://alps.example.org' }
      let (:entry_points) { ep_klass.generate_object_graph }
      let (:json_output) do
        '{"resources":{"http://alps.example.org/DRDs#list":{"href":"http://deployment.example.org/drds"}}}'
      end
      let (:expected_entry_points_json) do
        result =<<-JSON
          {
            "resources":
            {
              "http://alps.example.org/DRDs#list":
              {
                "href":"http://deployment.example.org/drds"
              },
                "http://alps.example.org/EntryPoints#list":
              {
                "href":"http://deployment.example.org/apis"
              },
                "http://alps.example.org/Leviathans#show":
              {
                "href":"http://deployment.example.org/leviathans/{uuid}"
              }
            }
          }
        JSON
      end
      let (:expected_entry_point_styled_microdata_html) do
        result =<<-HTML
          <!DOCTYPE html>
          <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
              <link rel="stylesheet" href="http://example.org/resources/css.css"/>
              <style>
          *[itemprop]::before {
            content: attr(itemprop) ": ";
            text-transform: capitalize;
          }
              </style>
            </head>
            <body>
              <ul>
                <li>
                  <p/>
                  <b>Rel: </b>
                  <a rel="http://alps.example.org/DRDs#list" href="http://alps.example.org/DRDs#list">http://alps.example.org/DRDs#list</a>
                  <b>  Url:  </b>
                  <a rel="http://deployment.example.org/drds" href="http://deployment.example.org/drds">http://deployment.example.org/drds</a>
                </li>
                <li>
                  <p/>
                  <b>Rel: </b>
                  <a rel="http://alps.example.org/EntryPoints#list" href="http://alps.example.org/EntryPoints#list">http://alps.example.org/EntryPoints#list</a>
                  <b>  Url:  </b>
                  <a rel="http://deployment.example.org/apis" href="http://deployment.example.org/apis">http://deployment.example.org/apis</a>
                </li>
                <li>
                  <p/>
                  <b>Rel: </b>
                  <a rel="http://alps.example.org/Leviathans#show" href="http://alps.example.org/Leviathans#show">http://alps.example.org/Leviathans#show</a>
                  <b>  Url:  </b>
                  <a rel="http://deployment.example.org/leviathans/{uuid}" href="http://deployment.example.org/leviathans/{uuid}">http://deployment.example.org/leviathans/{uuid}</a>
                </li>
              </ul>
            </body>
          </html>
        HTML
      end
      let (:expected_entry_point_xhtml) do
        result =<<-HTML
          <!DOCTYPE html>
          <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
              <link rel="stylesheet" href="http://example.org/resources/css.css"/>
              <style>
          *[itemprop]::before {
            content: attr(itemprop) ": ";
            text-transform: capitalize;
          }
              </style>
            </head>
            <body>
              <p/>
              <b>Rel: </b>
              <a rel="http://alps.example.org/DRDs#list" href="http://alps.example.org/DRDs#list">http://alps.example.org/DRDs#list</a>
              <b>  Url:  </b>
              <a rel="http://deployment.example.org/drds" href="http://deployment.example.org/drds">http://deployment.example.org/drds</a>
              <p/>
              <b>Rel: </b>
              <a rel="http://alps.example.org/EntryPoints#list" href="http://alps.example.org/EntryPoints#list">http://alps.example.org/EntryPoints#list</a>
              <b>  Url:  </b>
              <a rel="http://deployment.example.org/apis" href="http://deployment.example.org/apis">http://deployment.example.org/apis</a>
              <p/>
              <b>Rel: </b>
              <a rel="http://alps.example.org/Leviathans#show" href="http://alps.example.org/Leviathans#show">http://alps.example.org/Leviathans#show</a>
              <b>  Url:  </b>
              <a rel="http://deployment.example.org/leviathans/{uuid}" href="http://deployment.example.org/leviathans/{uuid}">http://deployment.example.org/leviathans/{uuid}</a>
            </body>
          </html>
        HTML
      end

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(entry_points_descriptor)
        @serializer = JsonHomeSerializer
      end

      it 'self-registers as a serializer for the json+home media-type' do
        expect(Serializer.registered_serializers[:json_home]).to eq(@serializer)
      end

      describe '#to_media_type' do
        it 'returns the resource represented as application/json+home' do
          serializer = @serializer.new(entry_points)
          expect(serializer.to_media_type).to be_json_eql(expected_entry_points_json)
        end

        it 'returns a valid html output when to_media_type is set to :html' do
          expect(entry_points.to_media_type(:html)).to be_equivalent_to(expected_entry_point_styled_microdata_html)
        end

        it 'returns a valid html output when to_media_type is set to :xhtml' do
          expect(entry_points.to_media_type(:xhtml)).to be_equivalent_to(expected_entry_point_xhtml)
        end
      end

      it 'raises an exception when an EntryPoint object does not have a resources method' do
        expect { @serializer.new(double('bad_entry_point_object')) }.to raise_error(
          "Target serializing object must be an EntryPoints object containing resources")
      end

      it 'generates a valid url with a forward slashes on a resource uri' do
        resources = [Crichton::Discovery::EntryPoint.new('/drds', 'drds', 'list', 'DRDs')]
        serializer = @serializer.new(Crichton::Discovery::EntryPoints.new(resources))
        expect(serializer.to_media_type).to eq(json_output)
      end

      it 'generates a valid url without a forward slashes on a resource uri' do
        resources = [Crichton::Discovery::EntryPoint.new('drds', 'drds', 'list', 'DRDs')]
        serializer = @serializer.new(Crichton::Discovery::EntryPoints.new(resources))
        expect(serializer.to_media_type).to eq(json_output)
      end
    end
  end
end

