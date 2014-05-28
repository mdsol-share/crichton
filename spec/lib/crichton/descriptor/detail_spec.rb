require 'spec_helper'
require 'crichton/descriptor/detail'

module Crichton
  module Descriptor
    describe Detail do
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor_document) { normalized_drds_descriptor['descriptors']['drds'] }
      let(:parent_descriptor) do
        descriptor = mock('parent_descriptor')
        descriptor.stub(:child_descriptor_document).with('drds').and_return(descriptor_document)
        descriptor.stub(:name).and_return('DRDs')
        descriptor
      end
      let(:descriptor) { Detail.new(resource_descriptor, parent_descriptor, 'drds') }
      let(:name_semantic) { descriptor.transitions['create'].semantics['name'] }

      describe '.new' do
        it 'returns a subclass of Profile' do
          descriptor.should be_a(Profile)
        end
  
        it_behaves_like 'a nested descriptor'
      end

      describe '#embed' do
        it 'returns the embed value for the descriptor' do
          descriptor_document['embed'] = 'single-optional'
          descriptor.embed.should == descriptor_document['embed']
        end
      end

      describe '#embed_type' do
        it 'returns :embed for single' do
          descriptor_document['embed'] = 'single'
          options = {}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :embed for multiple' do
          descriptor_document['embed'] = 'multiple'
          options = {}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :link for single-link' do
          descriptor_document['embed'] = 'single-link'
          options = {}
          descriptor.embed_type(options).should == :link
        end

        it 'returns :link for multiple-link' do
          descriptor_document['embed'] = 'multiple-link'
          options = {}
          descriptor.embed_type(options).should == :link
        end

        it 'returns :embed for single-optional without optional_embed_mode option' do
          descriptor_document['embed'] = 'single-optional'
          options = {}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :embed in case an unknown embed option is specified' do
          descriptor_document['embed'] = 'junk-optional'
          options = {}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :embed for multiple-optional without optional_embed_mode option' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :embed for multiple-optional-link without optional_embed_mode option' do
          descriptor_document['embed'] = 'multiple-optional-link'
          options = {}
          descriptor.embed_type(options).should == :link
        end

        it 'returns :embed for single-optional with optional_embed_mode option set to :embed' do
          descriptor_document['embed'] = 'single-optional'
          options = {embed_optional: {'drds' => :embed}}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :embed for multiple-optional with optional_embed_mode option set to :embed' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {embed_optional: {'drds' => :embed}}
          descriptor.embed_type(options).should == :embed
        end

        it 'returns :link for single-optional with optional_embed_mode option set to :link' do
          descriptor_document['embed'] = 'single-optional'
          options = {embed_optional: {'drds' => :link}}
          descriptor.embed_type(options).should == :link
        end

        it 'returns :link for multiple-optional with optional_embed_mode option set to :link' do
          descriptor_document['embed'] = 'multiple-optional'
          options = {embed_optional: {'drds' => :link}}
          descriptor.embed_type(options).should == :link
        end
      end

      describe '#embeddable?' do
        it 'returns true if an embed value is set' do
          descriptor_document['embed'] = 'optional'
          descriptor.embeddable?.should be_true
        end

        it 'returns false if an embed value is not set' do
          descriptor.embeddable?.should be_false
        end
      end
      
      describe '#metadata_links' do
        let(:profile_link) { mock('profile_link') }
        let(:type_link) { mock('type_link') }
        let(:help_link) { mock('help_link') }
        
        before do
          descriptor.stub(:profile_link).and_return(profile_link)
          descriptor.stub(:type_link).and_return(type_link)
          descriptor.stub(:help_link).and_return(help_link)
        end
                  
        after do
          descriptor.metadata_links.should include(@link)
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
          transition_descriptor.should be_safe
        end

        it 'returns false for descriptors whose type is not safe' do
          descriptor.should_not be_safe
        end
      end

      describe '#type_link' do
        it 'returns nil for transition descriptors' do
          descriptor.stub(:semantic?).and_return(false)
          descriptor.type_link.should be_nil
        end

        it 'returns the self link for semantic descriptors' do
          descriptor.type_link.href.should == descriptor.links['self'].absolute_href
        end

        it 'returns the absolute self link' do
          descriptor.type_link.href.should == 'http://alps.example.com/DRDs#drds'
        end
      end

      describe '#parent_descriptor' do
        it 'returns the parent of the descriptor' do
          descriptor.parent_descriptor.should == parent_descriptor
        end
      end

      describe '#source' do
        it 'returns the name of the descriptor if the local source is not specified' do
          descriptor.source.should == descriptor.name
        end

        it 'returns the local source if specified' do
          descriptor_document['source'] = 'source'
          descriptor.source.should == descriptor_document['source']
        end
      end

      describe '#sample' do
        it 'returns a sample value for the descriptor' do
          descriptor.sample.should == descriptor_document['sample']
        end
      end

      describe '#rt' do
        it 'returns the descriptor return type' do
          descriptor.rt.should == descriptor_document['rt']
        end
      end

      describe '#type' do
        it 'returns semantic' do
          descriptor.type.should == descriptor_document['type']
        end
      end

      describe '#field_type' do
        it 'returns the descriptor field_type' do
          name_semantic.field_type.should == 'text'
        end
      end

      describe '#validators' do
        it 'returns a hash' do
          name_semantic.validators.should include({ 'required' => nil, 'maxlength' => 50 })
        end

        it 'memoizes' do
          validators = name_semantic.validators
          name_semantic.validators.object_id == validators.object_id
        end
      end
    end
  end
end
