require 'spec_helper'

module Crichton
  describe '.clear_resource_descriptors' do
    before do
      Crichton.clear_resource_descriptors
    end

    it 'clears any registered resource descriptors' do
      Descriptors::Resource.register(drds_descriptor)
      Crichton.clear_resource_descriptors
      Descriptors::Resource.registered_resources.should be_empty
    end
  end
  
  describe '.resource_descriptors' do
    before do
      Crichton.clear_resource_descriptors
    end
    
    context 'with a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(resource_descriptor_fixtures)
      end
      
      it 'load resource descriptors from a resource descriptor directory if configured' do
        Crichton.resource_descriptors
      end
    end

    context 'without a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(nil)
      end
      
      it 'returns any registered resource descriptors' do
        descriptor = Descriptors::Resource.register(drds_descriptor)
        Crichton.resource_descriptors[descriptor.id].should == descriptor
      end

      it 'returns an empty hash if no resource descriptors are registered' do
        Crichton.resource_descriptors.should be_empty
      end
    end
  end
  
  module Descriptors
    describe  Resource do
      before do
        Resource.clear
      end

      describe '.clear' do
        it 'clears all registered resource descriptors' do
          Resource.register(drds_descriptor)
          Resource.clear
          Resource.registered_resources.should be_empty
        end
      end
      
      describe '.new' do
        it 'creates a resource descriptor whose id is the name:version of the resource_descriptor' do
          descriptor = Resource.new(drds_descriptor)
          descriptor.id.should == 'drds:v1.0.0'
        end
      end

      describe '.register' do
        it 'returns the registered resource descriptor instance' do
          Resource.register(drds_descriptor).instance_of?(Resource).should be_true
        end
        
        shared_examples_for 'a resource descriptor registration' do
          it 'registers a resource descriptor' do
            Resource.register(@descriptor)
            Resource.registered_resources['drds:v1.0.0'].is_a?(Resource).should be_true
          end
        end

        context 'with a filename as an argument' do
          before do
            @descriptor = drds_filename
          end
        
          it_behaves_like 'a resource descriptor registration'
          
          it 'raises an error if the filename is invalid' do
            expect { Resource.register('invalid_filename') }.to raise_error(ArgumentError, 
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
          
          it 'raises an error if no name is specified in the resource descriptor' do
            descriptor.delete('name')
            expect { Resource.register(descriptor) }.to raise_error(ArgumentError)
          end
  
          it 'raises an error if no version is specified in the resource descriptor' do
            descriptor.delete('version')
            expect { Resource.register(descriptor) }.to raise_error(ArgumentError)
          end
        end

        it 'raises an error when the resource descriptor is not a string or hash' do
          resource_descriptor = mock('invalid_descriptor')
          expect { Resource.register(resource_descriptor) }.to raise_error(ArgumentError)
        end
        
        it 'raises an error when the resource descriptor is already registered' do
          Resource.register(drds_descriptor)
          expect { Resource.register(drds_descriptor) }.to raise_error(ArgumentError)
        end
      end
      
      describe '.registered_resources' do
        it 'returns an empty hash hash if no resource descriptors are registered' do
          Resource.registered_resources.should be_empty
        end
        
        it 'returns a hash of registered resource descriptors instances keyed by resource descriptor id' do
          resource_descriptor = Resource.register(drds_descriptor)
          Resource.registered_resources[resource_descriptor.id].should == resource_descriptor
        end
      end

      describe '.registered_resources?' do
        it 'returns false if no resource descriptors are registered' do
          Resource.registered_resources?.should be_false
        end

        it 'returns true if resource descriptors are registered' do
          Resource.register(drds_descriptor)
          Resource.registered_resources?.should be_true
        end
      end
    end
    
    describe '#inspect' do
      it 'converts a resource descriptor to string, but does not include the underlying resource descriptor document' do
        descriptor = Resource.new(drds_descriptor)
        descriptor.inspect.should_not =~ /.*A list of DRDs.*/
      end
    end

    describe '#doc' do
      it 'returns the description specified in the resource descriptor' do
        resource_descriptor = Resource.new(drds_descriptor)
        resource_descriptor.doc.should == 'A list of DRDs.'
      end
    end

    describe '#name' do
      it 'returns the name specified in the resource descriptor' do
        resource_descriptor = Resource.new(drds_descriptor)
        resource_descriptor.name.should == 'drds'
      end
    end

    describe '#version' do
      it 'returns the verions specified in the resource descriptor' do
        resource_descriptor = Resource.new(drds_descriptor)
        resource_descriptor.version.should == 'v1.0.0'
      end
    end
  end
end
