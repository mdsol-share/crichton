require 'spec_helper' 
require 'crichton/descriptor/link'

module Crichton
  module Descriptor
    describe Link do
      let(:link) { Link.new(mock('resource_descriptor'), {'href' => 'link_url'}, 'rel') }
      
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
