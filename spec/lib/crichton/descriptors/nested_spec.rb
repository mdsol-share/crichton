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

    shared_examples_for 'a nested descriptor' do
      it 'responds to semantics' do
        descriptor.should respond_to(:semantics)
      end

      it 'responds to transitions' do
        descriptor.should respond_to(:transitions)
      end
    end
    
    let(:descriptor) { SimpleTestClass.new(@descriptor) }
    
    it_behaves_like 'a nested descriptor'
    
    describe '#semantics' do
      context 'with nested semantic descriptors' do
        before do
          @descriptor = drds_descriptor
        end
        
        it 'returns a populated hash' do
          descriptor.semantics.should_not be_empty
        end
        
        it 'returns a hash of semantic descriptors' do
          descriptor.semantics.all? { |_, descriptor| descriptor.type == 'semantic'}.should be_true
        end
      end
      
      context 'without nested semantic descriptors' do
        it 'returns an empty hash if there are no nested semantic descriptors' do
          @descriptor = drds_descriptor.reject { |k, _| k == 'semantics' }
          descriptor.semantics.should be_empty
        end
      end
    end

    describe '#transitions' do
      context 'with nested semantic descriptors' do
        before do
          @descriptor = drds_descriptor
        end

        it 'returns a populated hash' do
          descriptor.transitions.should_not be_empty
        end

        it 'returns a hash of transition descriptors' do
          types = %w(safe unsafe idempotent)
          descriptor.transitions.all? { |_, descriptor| types.include?(descriptor.type) }.should be_true
        end
      end

      context 'without nested semantic descriptors' do
        it 'returns an empty hash if there are no nested transition descriptors' do
          @descriptor = drds_descriptor.reject { |k, _| k == 'transitions' }
          descriptor.transitions.should be_empty
        end
      end
    end
  end
end
