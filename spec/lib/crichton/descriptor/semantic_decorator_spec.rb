require 'spec_helper'
require 'crichton/descriptor/semantic_decorator'

module Crichton
  module Descriptor
    describe SemanticDecorator do
      let(:parent_descriptor) do
        descriptor = mock('parent_descriptor')
        descriptor.stub(:child_descriptor_document).with('drds').and_return(@descriptor_document)
        descriptor.stub(:name).and_return("DRDs")
        descriptor
      end
      let(:descriptor) { Detail.new(mock('resource_descriptor'), parent_descriptor, 'drds') }
      let(:decorator) { SemanticDecorator.new(@target, descriptor) }
      
      describe '#source_defined?' do
        context 'with hash target' do
          it 'returns true if the hash includes the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            value = mock('value')
            @target = {'uuid' => value}
            decorator.source_defined?.should be_true
          end

          it 'returns false if the hash does not include the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            @target = {}
            decorator.source_defined?.should be_false
          end
        end

        context 'with object target' do
          it 'returns true if the object exposes the descriptor value' do
            @descriptor_document = {'source' => 'uuid'}
            value = mock('value')
            @target = Class.new do
              self.class.define_method(:uuid) { value }
            end
            decorator.should be_present
          end

          it 'returns false if the object does not expose the descriptor value' do
            @descriptor_document = {'source' => 'uuid'}
            @target = Class.new
            decorator.should be_present
          end
        end
      end
      
      describe '#value' do
        context 'with hash target' do
          it 'returns the value of the associated attribute of the hash' do
            @descriptor_document = {'name' => 'uuid' }
            value = mock('value')
            @target = {'uuid' => value}
            decorator.value.should == value
          end
        end
        
        context 'with object target' do
          it 'returns the value of the attribute of the object' do
            @descriptor_document = {'source' => 'uuid'}
            value = mock('value')
            @target = Class.new do 
              self.class.define_method('uuid') { value }
            end
            decorator.value.should == value
          end
        end

        context 'with object target' do
          it 'returns the value of the attribute of the object' do
            @descriptor_document = {'source' => 'uuid'}
            @target = nil
            logger = double(:logger)
            Crichton.stub(:logger).once.and_return(logger)
            logger.should_receive(:warn)
            decorator.value
          end
        end
      end
    end
  end
end
