require 'spec_helper' 
require 'crichton/descriptor/link'

module Crichton
  module Descriptor
    describe Link do
      let(:link) { Link.new(mock('resource_descriptor'), 'rel', 'link_url') }
      
      describe '#attributes' do
        it 'returns the attributes of the link' do
          link.attributes.should == {rel: 'rel', href: 'link_url'}
        end
      end
      
      describe '#rel' do
        it 'returns the link relationship' do
          link.rel.should == 'rel'
        end
      end

      describe '#url' do
        it 'returns the link url' do
          link.url.should == 'link_url'
        end
      end
    end
  end
end
