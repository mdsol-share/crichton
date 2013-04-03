require 'spec_helper'

module Crichton
  describe LinkDescriptor do
    let(:link) { LinkDescriptor.new('self', 'http://example.org') }
    
    describe '#rel' do
      it 'returns the link the relationship' do
        link.rel.should == 'self'
      end
    end

    describe '#href' do
      it 'returns the link the URL' do
        link.href.should == 'http://example.org'
      end
    end
  end
end
