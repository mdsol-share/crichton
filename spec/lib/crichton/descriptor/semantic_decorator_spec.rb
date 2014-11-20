require 'spec_helper'
require 'crichton/descriptor/semantic_decorator'

module Crichton
  module Descriptor
    describe SemanticDecorator do
      let(:parent_descriptor) do
        descriptor = double('parent_descriptor')
        allow(descriptor).to receive(:child_descriptor_document).with('drds').and_return(@descriptor_document)
        allow(descriptor).to receive(:name).and_return('DRDs')
        descriptor
      end
      let(:logger) { double(:logger) }
      let(:descriptor) { Detail.new(double('resource_descriptor'), parent_descriptor, 'drds') }
      let(:decorator) { SemanticDecorator.new(@target, descriptor) }
      
      describe '#source_defined?' do
        context 'with hash target' do
          it 'returns true if the hash includes the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            value = double('value')
            @target = {'uuid' => value}
            expect(decorator.source_defined?).to be true
          end

          it 'returns false if the hash does not include the descriptor value' do
            @descriptor_document = {'name' => 'uuid'}
            @target = {}
            expect(decorator.source_defined?).to be false
          end
        end

        context 'with object target' do
          it 'returns true if the object exposes the descriptor value' do
            @descriptor_document = {'source' => 'uuid'}
            value = double('value')
            @target = Class.new do
              self.class.send(:define_method, :uuid) { value }
            end
            expect(decorator).to be_present
          end

          it 'returns false if the object does not expose the descriptor value' do
            @descriptor_document = {'source' => 'uuid'}
            @target = Class.new
            expect(decorator).to be_present
          end
        end
      end
      
      describe '#value' do
        context 'with hash target' do
          it 'returns the value of the associated attribute of the hash' do
            @descriptor_document = {'name' => 'uuid' }
            value = double('value')
            @target = {'uuid' => value}
            expect(decorator.value).to eq(value)
          end
        end
        
        context 'with object target' do
          it 'returns the value of the attribute of the object' do
            @descriptor_document = {'source' => 'uuid'}
            value = double('value')
            @target = Class.new do 
              self.class.send(:define_method, :uuid) { value }
            end
            expect(decorator.value).to eq(value)
          end
        end

        context 'with object target' do
          before do
            @descriptor_document = {'source' => 'uuid'}
            allow(Crichton).to receive(:logger).once.and_return(logger)
          end

          after do
            decorator.value
          end

          it 'returns the value of the attribute of the object' do
            @target = nil
            expect(logger).to receive(:warn)
          end

          it 'returns the boolean value of the attribute of the object' do
            @target = Class.new do
              self.class.send(:define_method, :uuid) { false }
            end
            expect(logger).to_not receive(:warn)
          end

          it 'returns nil value of the attribute of the object and logs warning message' do
            @target = Class.new do
              self.class.send(:define_method, :uuid) { nil }
            end
            expect(logger).to receive(:warn)
          end
        end
      end
    end
  end
end
