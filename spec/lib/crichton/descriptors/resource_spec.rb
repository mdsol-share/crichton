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
        ResourceDescriptor.registry.should be_empty
      end
    end
    
    describe '.new' do
      let(:descriptor) { ResourceDescriptor.new(drds_descriptor) }

      it 'returns a subclass of BaseDescriptor' do
        descriptor.should be_a(BaseDescriptor)
      end
      
      it_behaves_like 'a nested descriptor'
    end

    describe '.register' do
      it 'returns the registered resource descriptor instance' do
        ResourceDescriptor.register(drds_descriptor).should be_instance_of(ResourceDescriptor)
      end
      
      shared_examples_for 'a resource descriptor registration' do
        it 'registers a resource descriptor' do
          ResourceDescriptor.register(@descriptor)
          ResourceDescriptor.registry['DRDs:v1.0.0'].should be_instance_of(ResourceDescriptor)
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
    
    describe '.registry' do
      it 'returns an empty hash hash if no resource descriptors are registered' do
        ResourceDescriptor.registry.should be_empty
      end
      
      it 'returns a hash of registered resource descriptors instances keyed by resource descriptor id' do
        resource_descriptor = ResourceDescriptor.register(drds_descriptor)
        ResourceDescriptor.registry[resource_descriptor.to_key].should == resource_descriptor
      end
    end

    describe '.registrations?' do
      it 'returns false if no resource descriptors are registered' do
        ResourceDescriptor.registrations?.should be_false
      end

      it 'returns true if resource descriptors are registered' do
        ResourceDescriptor.register(drds_descriptor)
        ResourceDescriptor.registrations?.should be_true
      end
    end
    
    let(:resource_descriptor) { ResourceDescriptor.new(drds_descriptor) }
    
    describe '#to_key' do
      it 'returns a key from the ID and version of the resource descriptor' do
        resource_descriptor.to_key.should == 'DRDs:v1.0.0'
      end
    end

    describe '#version' do
      it 'returns the verions specified in the resource descriptor' do
        resource_descriptor.version.should == 'v1.0.0'
      end
    end
  end
end
