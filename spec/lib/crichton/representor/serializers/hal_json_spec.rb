require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/hal_json'
require 'json_spec'

module Crichton
  module Representor
    describe HalJsonSerializer do
      let (:drds) do
        drd_klass.tap { |klass| klass.apply_methods }.all
      end

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(drds_descriptor)
        @serializer = HalJsonSerializer
      end

      it 'self-registers as a serializer for the hal+json media-type' do
        Serializer.registered_serializers[:hal_json].should == @serializer
      end

      describe '#as_media_type' do
        it 'returns the resource represented as application/hal+json' do
          serializer = @serializer.new(drds)
          serializer.to_media_type(conditions: 'can_do_anything').should be_json_eql(drds_hal_json)
        end
      end
    end
  end
end