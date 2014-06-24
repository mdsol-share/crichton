require 'spec_helper'
require 'crichton/descriptor/state'

module Crichton
  module Descriptor
    describe State do
      let(:state_descriptor) { normalized_drds_descriptor['descriptors']['drds']['states']['collection'] }
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor) { State.new(resource_descriptor, state_descriptor, 'collection') }
  
      describe '#doc' do
        it 'returns the underlying descriptor doc property' do
          expect(descriptor.doc).to eq(state_descriptor['doc'])
        end
      end
  
      describe '#id' do
        it 'returns the name of the state' do
          expect(descriptor.id).to eq('collection')
        end
      end
      
      describe '#location' do
        it 'returns the location of the state in the state machine' do
          expect(descriptor.location).to eq(state_descriptor['location'])
        end
      end
      
      describe '#transitions' do
        it 'returns a hash of state transition descriptors' do
          expect(descriptor.transitions['list']).not_to be_nil
        end
      end
    end
  end
end
