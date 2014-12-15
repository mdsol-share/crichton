require 'spec_helper'
require 'crichton/representor'
require 'crichton/representor/factory'
require 'crichton/representor/serializers/xhtml'

module Crichton
  module Representor
    describe XHTMLSerializer do

      let (:drds) do
        drd_klass.tap { |klass| klass.apply_methods }.all
      end
      
      let (:serializer) { XHTMLSerializer.new(drds) }

      before do
        # Can't apply methods without a stubbed configuration and registered descriptors
        stub_example_configuration
        Crichton.initialize_registry(drds_descriptor)
      end

      it 'self-registers as a serializer for the xhtml media-type' do
        expect(Serializer.registered_serializers[:xhtml]).to eq(XHTMLSerializer)
      end

      it 'self-registers as a serializer for the html media-type' do
        expect(Serializer.registered_serializers[:html]).to eq(XHTMLSerializer)
      end
      
      describe('#as_media_type') do
        context 'without styled interface for API surfing' do
          it 'returns the resource represented as xhtml' do
            expect(serializer.as_media_type(conditions: 'can_do_anything')).to be_equivalent_to(drds_microdata_html)
          end
        end

        context 'with styled interface for API surfing' do
          it 'returns the resource represented as xhtml' do
            options = {conditions: 'can_do_anything', semantics: :styled_microdata}
            expect(serializer.as_media_type(options)).to be_equivalent_to(drds_styled_microdata_html)
          end

          it 'returns the resource represented as xhtml with linked resources' do
            options = {conditions: 'can_do_anything', semantics: :styled_microdata, embed_optional: {'items' => :link}}
            expect(serializer.as_media_type(options)).to be_equivalent_to(drds_styled_microdata_embed_html)
          end
        end
      end
      
        describe '#raise_abstract' do        
          let (:builder) { XHTMLSerializer::BaseSemanticBuilder.new(:xhtml, drds, nil, serializer) }
        
          it 'raises for #element_tag' do
            expect {builder.send(:element_tag)}.to raise_error(RuntimeError, "#element_tag is an abstract method that must be implemented.")
          end
          
          it 'raises for #add_form_transition' do
            expect {builder.send(:add_form_transition, :transition)}.to raise_error(RuntimeError, "#add_form_transition is an abstract method that must be implemented.")
          end
          
          it 'raises for #add_semantic' do
            expect {builder.send(:add_semantic, :semantic, {})}.to raise_error(RuntimeError, "#add_semantic is an abstract method that must be implemented.")
          end
      end
    end
  end
end
