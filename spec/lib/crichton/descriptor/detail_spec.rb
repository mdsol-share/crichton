require 'spec_helper'

module Crichton
  module Descriptor
    describe Detail do
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor_document) { drds_descriptor['descriptors']['drds'] }
      let(:parent_descriptor) do
        descriptor = mock('parent_descriptor')
        descriptor.stub(:child_descriptor_document).with('drds').and_return(descriptor_document)
        descriptor
      end
      let(:descriptor) { Detail.new(resource_descriptor, parent_descriptor, 'drds') }
  
      describe '.new' do
        it 'returns a subclass of Profile' do
          descriptor.should be_a(Profile)
        end
  
        it_behaves_like 'a nested descriptor'
      end

      describe '#embed' do
        it 'returns the embed value for the descriptor' do
          descriptor_document['embed'] = 'optional'
          descriptor.embed.should == descriptor_document['embed']
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
        it 'includes the descriptor profile link' do
          simple_test_class.metadata_links.map(&:name).should include('profile')
        end

        it 'includes the descriptor type link' do
          simple_test_class.metadata_links.map(&:name).should include('type')
        end

        it 'includes the descriptor help link' do
          simple_test_class.metadata_links.map(&:name).should include('help')
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
    end
  end
end
