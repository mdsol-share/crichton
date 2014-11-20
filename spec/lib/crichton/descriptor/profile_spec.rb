require 'spec_helper'
require 'crichton/descriptor/profile'

module Crichton
  module Descriptor
    describe Profile do
      let(:descriptors) { normalized_drds_descriptor['descriptors'] }
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor) { Profile.new(resource_descriptor, @descriptor) }

      before do
        @descriptor = descriptors['drds']
      end

      describe '.new' do
        it 'returns a subclass of Base' do
          expect(descriptor).to be_a(Base)
        end

        it_behaves_like 'a nested descriptor'
      end
  
      describe '#descriptors' do
        context 'with nested descriptors' do
          it 'returns a populated array' do
            expect(descriptor.descriptors).not_to be_empty
          end
  
          it 'returns an array of descriptors' do
            expect(descriptor.descriptors.all? { |descriptor| descriptor.is_a?(Base) }).to be true
          end
        end
  
        context 'without nested descriptors' do
          it 'returns an empty array if there are no nested descriptors' do
            @descriptor = drds_descriptor.reject { |k, _| k == 'descriptors' }
            expect(descriptor.descriptors).to be_empty
          end
        end
      end

      describe '#help_link' do
        it 'returns the help link in the descriptor' do
          descriptors['drds']['links'] = {'help' => 'help_link'}
          expect(descriptor.help_link.href).to eq('help_link')
        end
        
        it 'returns the resource descriptor help link if no help link in descriptor' do
          link = double('help_link')
          allow(resource_descriptor).to receive(:help_link).and_return(link)
          expect(descriptor.help_link).to eq(link)
        end
      end

      describe '#links' do
        it 'returns the descriptor links' do
          expect(descriptor.links['self']).not_to be_nil
        end
      end

      describe '#semantics' do
        context 'with nested semantic descriptors' do
          it 'returns a populated hash' do
            expect(descriptor.semantics).not_to be_empty
          end
  
          it 'returns an hash of semantic descriptors' do
            expect(descriptor.semantics.all? { |_, descriptor| descriptor.semantic? }).to be true
          end
        end 
  
        context 'without nested semantic descriptors' do
          it 'returns an empty hash if there are no nested semantic descriptors' do
            @descriptor['descriptors'].reject! { |_, descriptor| descriptor['type'] == 'semantic' }
            expect(descriptor.semantics).to be_empty
          end
        end
      end
  
      describe '#transitions' do
        context 'with nested transition descriptors' do
          it 'returns a populated hash' do
            expect(descriptor.transitions).not_to be_empty
          end
  
          it 'returns a hash of transition descriptors' do
            expect(descriptor.transitions.all? { |_, descriptor| descriptor.transition? }).to be true
          end
        end
  
        context 'without nested transition descriptors' do
          it 'returns an empty hash if there are no nested transition descriptors' do
            @descriptor['descriptors'].reject! { |descriptor| descriptor['type'] != 'semantic' }
            expect(descriptor.transitions).to be_empty
          end
        end
      end
    end
  end
end
