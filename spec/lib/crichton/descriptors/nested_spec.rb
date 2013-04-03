require 'spec_helper'

module Crichton
  describe NestedDescriptors do
    class SimpleTestClass
      include NestedDescriptors
      
      def initialize(descriptor_document)
        @descriptor_document = descriptor_document
      end

      attr_reader :descriptor_document
    end
    
    let(:top_level_descriptor) { SimpleTestClass.new(@descriptor) }
    
    describe '#semantics' do
      context 'with nested semantic descriptors' do
        before do
          @descriptor = drds_descriptor
        end
        
        it 'returns a populated hash' do
          top_level_descriptor.semantics.should_not be_empty
        end
        
        it 'returns a hash of semantic descriptors' do
          top_level_descriptor.semantics.all? { |_, descriptor| descriptor.type == 'semantic'}.should be_true
        end
      end
      
      context 'without nested semantic descriptors' do
        it 'returns an empty hash if there are no nested semantic descriptors' do
          @descriptor = drds_descriptor.reject { |k, _| k == 'semantics' }
          top_level_descriptor.semantics.should be_empty
        end
      end
    end

    describe '#transitions' do
      context 'with nested semantic descriptors' do
        before do
          @descriptor = drds_descriptor
        end

        it 'returns a populated hash' do
          top_level_descriptor.transitions.should_not be_empty
        end

        it 'returns a hash of transition descriptors' do
          types = %w(safe unsafe idempotent)
          top_level_descriptor.transitions.all? { |_, descriptor| types.include?(descriptor.type) }.should be_true
        end
      end

      context 'without nested semantic descriptors' do
        it 'returns an empty hash if there are no nested transition descriptors' do
          @descriptor = drds_descriptor.reject { |k, _| k == 'transitions' }
          top_level_descriptor.transitions.should be_empty
        end
      end
    end
  end
end
