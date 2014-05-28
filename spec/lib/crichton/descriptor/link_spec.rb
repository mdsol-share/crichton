require 'spec_helper' 
require 'crichton/descriptor/link'

module Crichton
  module Descriptor
    describe Link do
      let(:link) { Link.new(double('resource_descriptor'), 'rel', 'link_url') }
      
      describe '#attributes' do
        it 'returns the attributes of the link' do
          expect(link.attributes).to eq({rel: 'rel', href: 'link_url'})
        end
      end
      
      describe '#rel' do
        it 'returns the link relationship' do
          expect(link.rel).to eq('rel')
        end
      end

      describe '#url' do
        it 'returns the link url' do
          expect(link.url).to eq('link_url')
        end
      end
    end
  end
end
