require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/hal'
require 'json_spec'

#TODO: Create single Representor Test Class, and Merge this test with XHTML Test
module Crichton
  module Representor
    describe HalJsonSerializer do
      class ::DRD
        include Representor::State
        extend Representor::Factory

        represents :drd

        def self.apply_methods
          data_semantic_descriptors.each do |descriptor|
            name = descriptor.name
            define_method(name) { @attributes[name] }
          end
        end

        def self.all(options = nil)
          drds = {
              'total_count' => 2,
              'items' => 2.times.map { |i| new(i) }
          }
          build_state_representor(drds, :drds, {state: 'collection'})
        end

        def initialize(i)
          @attributes = {}
          @attributes = %w(name status kind leviathan_uuid built_at).inject({}) { |h, attr| h[attr] = "#{attr}_#{i}"; h }
          @attributes['uuid'] = i
        end

        # TODO: develop state specification options for embedded semantics
        def state
          :activated
        end

        def leviathan_url
          # Note: this is not advocating templating this, but rather just a method to demonstrate
          # the protocol implementation for URI source.
          "http://example.org/leviathan/#{leviathan_uuid}" if leviathan_uuid =~ /_1/
        end
      end

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
