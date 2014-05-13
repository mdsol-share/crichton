require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/hale_json'
require 'json_spec'

module Crichton
  module Representor
    describe HaleJsonSerializer do
      let (:drds) do
        drd_klass.tap { |klass| klass.apply_methods }.all
      end

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(new_drds_descriptor)
        @serializer = HaleJsonSerializer
      end
      
      after do
        Crichton.clear_registry
      end

      it 'self-registers as a serializer for the hale+json media-type' do
        Serializer.registered_serializers[:hale_json].should == @serializer
      end

      describe '#as_media_type' do
        it 'returns the resource represented as application/vnd.hale+json' do
          serializer = @serializer.new(drds)
          serializer.to_media_type(conditions: 'can_do_anything').should be_json_eql(drds_hale_json)
        end
      end
    end
  end
end
