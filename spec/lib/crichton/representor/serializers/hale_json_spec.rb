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
      let(:serializer) { HaleJsonSerializer }

      it 'self-registers as a serializer for the hale+json media-type' do
        expect(Serializer.registered_serializers[:hale_json]).to eq(serializer)
      end
=begin
      describe '#as_media_type' do
        after do
          stub_example_configuration
          Crichton.initialize_registry(@document || drds_descriptor)
          expect(serializer.new(drds).to_media_type(conditions: 'can_do_anything')).to be_json_eql(@hale)
        end

        it 'returns the resource represented as application/vnd.hale+json' do
          @hale = drds_hale_json
        end

        it 'returns resource representation without semantic data when no semantic descriptor is specified' do
          @hale = JSON.load(drds_hale_json).except('total_count').to_json
          @document = drds_descriptor.tap { |doc| doc['resources']['drds']['descriptors'].delete({ 'href' => 'total_count' }) }
        end

        it 'returns resource representation with multi attribute when cardinality is specified' do
          @hale = JSON.load(drds_hale_json).tap do
            |hale| hale['_links']['create']['data']['name'].merge!({ 'multi' => 'true' })
          end.to_json
          @document = normalized_drds_descriptor.tap do
            |doc| doc['descriptors']['drds']['descriptors']['create']['descriptors']['name'].merge!({ 'cardinality' => 'multiple' })
          end
        end
      end
=end
    end
  end
end
