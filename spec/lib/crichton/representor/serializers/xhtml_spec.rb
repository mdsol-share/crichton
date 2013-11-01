require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/xhtml'

module Crichton
  module Representor
    describe XHTMLSerializer do

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(drds_descriptor)
        DRD.apply_methods
      end

      it 'self-registers as a serializer for the xhtml media-type' do
        Serializer.registered_serializers[:xhtml].should == XHTMLSerializer
      end

      it 'self-registers as a serializer for the html media-type' do
        Serializer.registered_serializers[:html].should == XHTMLSerializer
      end
      
      describe '#as_media_type' do
        let (:serializer) { XHTMLSerializer.new(DRD.all) }

        context 'without styled interface for API surfing' do
          it 'returns the resource represented as xhtml' do
            serializer.as_media_type(conditions: 'can_do_anything').should be_equivalent_to(drds_microdata_html)
          end
        end

        context 'with styled interface for API surfing' do
          it 'returns the resource represented as xhtml' do
            options = {conditions: 'can_do_anything', semantics: :styled_microdata}
            serializer.as_media_type(options).should be_equivalent_to(drds_styled_microdata_html)
          end

          it 'returns the resource represented as xhtml with linked resources' do
            options = {conditions: 'can_do_anything', semantics: :styled_microdata, embed_optional: {'items' => :link}}
            serializer.as_media_type(options).should be_equivalent_to(drds_styled_microdata_embed_html)
          end
        end
      end
    end
  end
end
