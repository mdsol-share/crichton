require 'spec_helper'

module Crichton
  module Descriptors
    describe Semantic do
      let(:descriptor_document) { drds_descriptor }
      let(:descriptor) { Semantic.new(descriptor_document) }

      describe '.new' do
        it 'returns a subclass of Base' do
          descriptor.should be_a(Base)
        end
      end

      describe '#sample' do
        it 'returns a sample value for the descriptor' do
          descriptor.sample.should == descriptor_document['sample']
        end
      end

      describe '#type' do
        it 'returns semantic' do
          descriptor.type.should == 'semantic'
        end
      end
    end
  end
end
