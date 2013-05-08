require 'spec_helper'

module Crichton
  module Descriptor
    describe SemanticDecorator do
      let(:descriptor) { Detail.new(mock('resource_descriptor'), @descriptor_document) }
      let(:decorator) { SemanticDecorator.new(@target, descriptor) }
      
      describe '#present?' do
        context 'with hash target' do
          it 'returns true if the hash includes the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            value = mock('value')
            @target = {'uuid' => value}
            decorator.should be_present
          end

          it 'returns false if the hash does not include the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            @target = {}
            decorator.should_not be_present
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
      end
    end
  end
end
