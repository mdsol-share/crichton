require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/hal_json'
require 'json_spec'

#TODO: Create single Representor Test Class, and Merge this test with XHTML Test
module Crichton
  module Representor
    describe HalJsonSerializer do


      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(drds_descriptor)
        DRD.apply_methods
        @serializer = HalJsonSerializer
      end

      it 'self-registers as a serializer for the hal+json media-type' do
        Serializer.registered_serializers[:hal_json].should == @serializer
      end


      describe '#as_media_type' do
        it 'returns the resource represented as application/hal+json' do
          serializer = @serializer.new(DRD.all)
          serializer.to_media_type(conditions: 'can_do_anything').should be_json_eql(drds_hal_json)
        end
      end
    end
  end
end
