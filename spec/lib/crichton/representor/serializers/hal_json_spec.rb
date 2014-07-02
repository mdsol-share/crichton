require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/hal_json'

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
        expect(Serializer.registered_serializers[:hal_json]).to eq(@serializer)
      end

      describe '#as_media_type' do
        it 'returns the resource represented as application/hal+json' do
          serializer = @serializer.new(drds)
          expect(serializer.to_media_type(conditions: 'can_do_anything')).to be_json_eql(drds_hal_json)
        end
      end
    end

    describe "class" do

      it "returns the correct reserved key for a href" do
        expect(Crichton::Representor::HalJsonSerializer::RESERVED_HREF).to eq :href
      end

      it "retursn the correct reserved key for links" do
        expect(Crichton::Representor::HalJsonSerializer::RESERVED_LINKS).to eq :_links
      end
    end
  end
end
