require 'spec_helper'

module Crichton
  module Descriptor
    describe Detail do
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor_document) { drds_descriptor['descriptors'].first }
      let(:descriptor) { Detail.new(resource_descriptor, descriptor_document) }
  
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
  
      describe '#href' do
        it 'returns the href in the descriptor document' do
          descriptor.href.should == descriptor_document['href']
        end
      end
  
      describe '#protocol_descriptor' do
        it 'returns a protocol description for the specified protocol' do
          protocol_descriptor = mock('protocol_descriptor')
          resource_descriptor.stub(:protocol_transition).with('http', 'list').and_return(protocol_descriptor)
          
          transition_descriptor = descriptor_document['descriptors'].detect { |descriptor| descriptor['id'] == 'list' }
          descriptor =  Detail.new(resource_descriptor, transition_descriptor)
          descriptor.protocol_descriptor('http').should == protocol_descriptor
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
