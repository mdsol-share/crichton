require 'spec_helper'

module Crichton
  describe  ResourceDescriptor do
    before do
      ResourceDescriptor.clear
    end

    describe '.clear' do
      it 'clears all registered resource descriptors' do
        ResourceDescriptor.register(drds_descriptor)
        ResourceDescriptor.clear
        ResourceDescriptor.registered_resources.should be_empty
      end
    end
    
    describe '.new' do
      it 'returns a subclass of BaseDescriptor' do
        descriptor = ResourceDescriptor.new(drds_descriptor)
        descriptor.should be_a(BaseDescriptor)
      end
    end

    describe '.register' do
      it 'returns the registered resource descriptor instance' do
        ResourceDescriptor.register(drds_descriptor).should be_instance_of(ResourceDescriptor)
      end
      
      shared_examples_for 'a resource descriptor registration' do
        it 'registers a resource descriptor' do
          ResourceDescriptor.register(@descriptor)
          ResourceDescriptor.registered_resources['drds:v1.0.0'].should be_instance_of(ResourceDescriptor)
        end
      end

      context 'with a filename as an argument' do
        before do
          @descriptor = drds_filename
        end
      
        it_behaves_like 'a resource descriptor registration'
        
        it 'raises an error if the filename is invalid' do
          expect { ResourceDescriptor.register('invalid_filename') }.to raise_error(ArgumentError, 
            'Filename invalid_filename is not valid.'
          )
        end
      end
      
      context 'with a hash resource descriptor as an argument' do
        before do
          @descriptor = drds_descriptor
        end
      
        it_behaves_like 'a resource descriptor registration'
      end

      context 'with an invalid resource descriptor' do
        let(:descriptor) { drds_descriptor.dup }

        it 'raises an error if no id is specified in the resource descriptor' do
          descriptor.delete('id')
          expect { ResourceDescriptor.register(descriptor) }.to raise_error(ArgumentError)
        end

        it 'raises an error if no name is specified in the resource descriptor' do
          descriptor.delete('name')
          expect { ResourceDescriptor.register(descriptor) }.to raise_error(ArgumentError)
        end

        it 'raises an error if no version is specified in the resource descriptor' do
          descriptor.delete('version')
          expect { ResourceDescriptor.register(descriptor) }.to raise_error(ArgumentError)
        end
      end

      it 'raises an error when the resource descriptor is not a string or hash' do
        resource_descriptor = mock('invalid_descriptor')
        expect { ResourceDescriptor.register(resource_descriptor) }.to raise_error(ArgumentError)
      end
      
      it 'raises an error when the resource descriptor is already registered' do
        ResourceDescriptor.register(drds_descriptor)
        expect { ResourceDescriptor.register(drds_descriptor) }.to raise_error(ArgumentError)
      end
    end
    
    describe '.registered_resources' do
      it 'returns an empty hash hash if no resource descriptors are registered' do
        ResourceDescriptor.registered_resources.should be_empty
      end
      
      it 'returns a hash of registered resource descriptors instances keyed by resource descriptor id' do
        resource_descriptor = ResourceDescriptor.register(drds_descriptor)
        ResourceDescriptor.registered_resources[resource_descriptor.id].should == resource_descriptor
      end
    end

    describe '.registered_resources?' do
      it 'returns false if no resource descriptors are registered' do
        ResourceDescriptor.registered_resources?.should be_false
      end

      it 'returns true if resource descriptors are registered' do
        ResourceDescriptor.register(drds_descriptor)
        ResourceDescriptor.registered_resources?.should be_true
      end
    end

    describe '#entry_point' do
      it 'returns a hash of entry points keyed by protocol' do
        resource_descriptor = ResourceDescriptor.new(drds_descriptor)
        resource_descriptor.entry_point.should == {'http' => 'drds'}
      end
    end

    describe '#version' do
      it 'returns the verions specified in the resource descriptor' do
        resource_descriptor = ResourceDescriptor.new(drds_descriptor)
        resource_descriptor.version.should == 'v1.0.0'
      end
    end
  end
end
