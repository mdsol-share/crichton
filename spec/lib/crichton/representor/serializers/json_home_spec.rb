require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/json_home'
require 'json_spec'

module Crichton
  module Representor
    describe JsonHomeSerializer do
      let(:deployment_base_uri) { 'http://deployment.example.org' }
      let (:entry_points) do
        ep_klass.generate_object_graph
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

      describe '#as_media_type' do
        it 'returns the resource represented as application/json+home' do
          puts "\n\n *** ENTRY_POINTS: #{entry_points.inspect} *** \n\n"
          serializer = @serializer.new(entry_points)
          serializer.to_media_type.should be_json_eql(entry_points_json)
        end
      end

    end
  end
end

