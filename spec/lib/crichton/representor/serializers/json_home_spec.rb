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
        '{"resources":{"http://alps.example.org/DRDs/#list":{"href":"http://deployment.example.org/drds"}}}'
      end

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(entry_points_descriptor)
        @serializer = JsonHomeSerializer
      end

      it 'self-registers as a serializer for the json+home media-type' do
        Serializer.registered_serializers[:json_home].should == @serializer
      end

      describe '#to_media_type' do
        it 'returns the resource represented as application/json+home' do
          serializer = @serializer.new(entry_points)
          serializer.to_media_type.should be_json_eql(entry_points_json)
        end

        it 'returns a valid html output when to_media_type is set to :html' do
          entry_points.to_media_type(:html).should be_equivalent_to(entry_points_html)
        end

        it 'returns a valid html output when to_media_type is set to :xhtml' do
          entry_points.to_media_type(:xhtml).should be_equivalent_to(entry_points_xhtml)
        end
      end

      it 'raises an exception when an EntryPoint object does not have a resources method' do
        expect { @serializer.new(mock('bad_entry_point_object')) }.to raise_error(
          "Target serializing object must be an EntryPoints object containing resources")
      end

      it 'generates a valid url with a forward slashes on a resource uri' do
        resources = [Crichton::Discovery::EntryPoint.new('/drds', 'drds', 'list', 'DRDs')]
        serializer = @serializer.new(Crichton::Discovery::EntryPoints.new(resources))
        serializer.to_media_type.should == json_output
      end

      it 'generates a valid url without a forward slashes on a resource uri' do
        resources = [Crichton::Discovery::EntryPoint.new('drds', 'drds', 'list', 'DRDs')]
        serializer = @serializer.new(Crichton::Discovery::EntryPoints.new(resources))
        serializer.to_media_type.should == json_output
      end
    end
  end
end

