require 'spec_helper'
require 'crichton/descriptor/detail'

module Crichton
  module Descriptor
    describe Detail do
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor_document) { normalized_drds_descriptor['descriptors']['drds'] }
      let(:parent_descriptor) do
        descriptor = double('parent_descriptor')
        allow(descriptor).to receive(:child_descriptor_document).with('drds').and_return(@descriptor || descriptor_document)
        allow(descriptor).to receive(:name).and_return('DRDs')
        descriptor
      end
      let(:descriptor) { Detail.new(resource_descriptor, parent_descriptor, 'drds') }
      let(:name_semantic) { descriptor.transitions['create'].semantics['name'] }

      describe '.new' do
        it 'returns a subclass of Profile' do
          expect(descriptor).to be_a(Profile)
        end
  
        it_behaves_like 'a nested descriptor'
      end

      describe '#embed' do
        it 'returns the embed value for the descriptor' do
          descriptor_document['embed'] = 'single-optional'
          expect(descriptor.embed).to eq(descriptor_document['embed'])
        end
      end

      describe '#embed_type' do
        it 'returns :embed for single' do
          descriptor_document['embed'] = 'single'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :embed for multiple' do
          descriptor_document['embed'] = 'multiple'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :link for single-link' do
          descriptor_document['embed'] = 'single-link'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:link)
        end

        it 'returns :link for multiple-link' do
          descriptor_document['embed'] = 'multiple-link'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:link)
        end

        it 'returns :embed for single-optional without optional_embed_mode option' do
          descriptor_document['embed'] = 'single-optional'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :embed in case an unknown embed option is specified' do
          descriptor_document['embed'] = 'junk-optional'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :embed for multiple-optional without optional_embed_mode option' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :embed for multiple-optional-link without optional_embed_mode option' do
          descriptor_document['embed'] = 'multiple-optional-link'
          options = {}
          expect(descriptor.embed_type(options)).to eq(:link)
        end

        it 'returns :embed for single-optional with optional_embed_mode option set to :embed' do
          descriptor_document['embed'] = 'single-optional'
          options = {embed_optional: {'drds' => :embed}}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :embed for multiple-optional with optional_embed_mode option set to :embed' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {embed_optional: {'drds' => :embed}}
          expect(descriptor.embed_type(options)).to eq(:embed)
        end

        it 'returns :link for single-optional with optional_embed_mode option set to :link' do
          descriptor_document['embed'] = 'single-optional'
          options = {embed_optional: {'drds' => :link}}
          expect(descriptor.embed_type(options)).to eq(:link)
        end

        it 'returns :link for multiple-optional with optional_embed_mode option set to :link' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {embed_optional: {'drds' => :link}}
          expect(descriptor.embed_type(options)).to eq(:link)
        end
      end

      describe '#embeddable?' do
        it 'returns true if an embed value is set' do
          descriptor_document['embed'] = 'optional'
          expect(descriptor.embeddable?).to be true
        end

        it 'returns false if an embed value is not set' do
          expect(descriptor.embeddable?).to be false
        end
      end
      
      describe '#metadata_links' do
        let(:profile_link) { double('profile_link') }
        let(:type_link) { double('type_link') }
        let(:help_link) { double('help_link') }
        
        before do
          allow(descriptor).to receive(:profile_link).and_return(profile_link)
          allow(descriptor).to receive(:type_link).and_return(type_link)
          allow(descriptor).to receive(:help_link).and_return(help_link)
        end
                  
        after do
          expect(descriptor.metadata_links).to include(@link)
        end

        it 'includes the descriptor profile link' do
          @link = profile_link
        end

        it 'includes the descriptor type link' do
          @link = type_link
        end

        it 'includes the descriptor help link' do
          @link = help_link
        end
      end

      describe '#safe?' do
        it 'returns true for descriptors whose type is safe' do
          transition_descriptor = descriptor.transitions['list']
          expect(transition_descriptor).to be_safe
        end

        it 'returns false for descriptors whose type is not safe' do
          expect(descriptor).not_to be_safe
        end
      end

      describe '#type_link' do
        it 'returns nil for transition descriptors' do
          allow(descriptor).to receive(:semantic?).and_return(false)
          expect(descriptor.type_link).to be_nil
        end

        it 'returns the self link for semantic descriptors' do
          expect(descriptor.type_link.href).to eq(descriptor.links['self'].absolute_href)
        end

        it 'returns the absolute self link' do
          expect(descriptor.type_link.href).to eq('http://localhost:3000/alps/DRDs#drds')
        end

        it 'can be external' do
          allow(descriptor.type_link).to receive(:href).and_return('http://example.com/alps/DRDs#drds')
          expect(descriptor.type_link.absolute_href).to eq(descriptor.type_link.href)
        end

      end

      describe '#parent_descriptor' do
        it 'returns the parent of the descriptor' do
          expect(descriptor.parent_descriptor).to eq(parent_descriptor)
        end
      end

      describe '#source' do
        it 'returns the name of the descriptor if the local source is not specified' do
          expect(descriptor.source).to eq(descriptor.name)
        end

        it 'returns the local source if specified' do
          descriptor_document['source'] = 'source'
          expect(descriptor.source).to eq(descriptor_document['source'])
        end
      end

      describe '#sample' do
        it 'returns a sample value for the descriptor' do
          expect(descriptor.sample).to eq(descriptor_document['sample'])
        end
      end

      describe '#rt' do
        it 'returns the descriptor return type' do
          expect(descriptor.rt).to eq(descriptor_document['rt'])
        end
      end

      describe '#type' do
        it 'returns semantic' do
          expect(descriptor.type).to eq(descriptor_document['type'])
        end
      end

      describe '#field_type' do
        it 'returns the descriptor field_type' do
          expect(name_semantic.field_type).to eq('text')
        end
      end

      describe '#multiple?' do
        it 'returns false when cardinality is not specified' do
          expect(name_semantic.multiple?).to be false
        end

        it 'returns false when cardinality is single' do
          @descriptor = normalized_drds_descriptor.tap do |doc|
            doc['descriptors']['drds']['descriptors']['create']['descriptors']['name'].merge!({ 'cardinality' => 'single' })
          end
          expect(name_semantic.multiple?).to be false
        end

        it 'returns false when cardinality is single' do
          @descriptor = normalized_drds_descriptor.tap do |doc|
            doc['descriptors']['drds']['descriptors']['create']['descriptors']['name'].merge!({ 'cardinality' => 'multiple' })
          end
          expect(name_semantic.multiple?).to be true
        end
      end

      describe '#validators' do
        it 'returns a hash' do
          expect(name_semantic.validators).to include({ 'required' => nil, 'maxlength' => 50 })
        end

        it 'memoizes' do
          validators = name_semantic.validators
          name_semantic.validators.object_id == validators.object_id
        end
      end
    end
  end
end
