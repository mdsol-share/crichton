require 'spec_helper'

module Crichton
  module Descriptor
    describe Resource do
      before do
        Resource.clear_registry
      end
  
      describe '.clear_registry' do
        it 'clears all registered resource descriptors' do
          Resource.register(drds_descriptor)
          Resource.clear_registry
          Resource.registry.should be_empty
        end
      end
      
      describe '.new' do
        let(:descriptor) { Resource.new(drds_descriptor) }
  
        it 'returns a subclass of Profile' do
          descriptor.should be_a(Profile)
        end
        
        it_behaves_like 'a nested descriptor'
      end
  
      describe '.register' do
        it 'returns the registered resource descriptor instance' do
          Resource.register(drds_descriptor).should be_instance_of(Resource)
        end
        
        shared_examples_for 'a resource descriptor registration' do
          it 'registers a resource descriptor' do
            Resource.register(@descriptor)
            Resource.registry['DRDs:v1.0.0'].should be_instance_of(Resource)
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
  
          it 'raises an error if no id is specified in the resource descriptor' do
            descriptor.delete('id')
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
      
      describe '.registry' do
        it 'returns an empty hash hash if no resource descriptors are registered' do
          Resource.registry.should be_empty
        end
        
        it 'returns a hash of registered resource descriptors instances keyed by resource descriptor id' do
          resource_descriptor = Resource.register(drds_descriptor)
          Resource.registry[resource_descriptor.to_key].should == resource_descriptor
        end
      end
  
      describe '.registrations?' do
        it 'returns false if no resource descriptors are registered' do
          Resource.registrations?.should be_false
        end
  
        it 'returns true if resource descriptors are registered' do
          Resource.register(drds_descriptor)
          Resource.registrations?.should be_true
        end
      end
      
      let(:resource_descriptor) { Resource.new(drds_descriptor) }
      
      describe '#inspect' do
        it 'includes the @key ivar' do
          resource_descriptor.to_key
          resource_descriptor.inspect.should =~ /.*@key=.*/
        end
      end
      
      describe '#protocols' do
        it 'returns a hash protocol-specific transition descriptors keyed by protocol' do
          resource_descriptor.protocols['http'].should_not be_empty
        end
        
        context 'with unknown protocol in descriptor document' do
          it 'raises an error' do
            resource_descriptor.descriptor_document['protocols'] = {'unknown' => {}}
            expect { resource_descriptor.protocols }.to raise_error(
              'Unknown protocol unknown defined in resource descriptor document DRDs.'
            )
          end
        end
      end
      
      describe '#protocol_transition' do
        it 'returns a protocol specific transition descriptor' do
          resource_descriptor.protocol_transition('http', 'list').should be_instance_of(Http)
        end
      end

      describe '#states' do
        it 'returns as hash of state descriptors keyed by resource' do
          resource_descriptor.states['drds'].should_not be_empty
        end
      end
  
      describe '#to_key' do
        it 'returns a key from the ID and version of the resource descriptor' do
          resource_descriptor.to_key.should == 'DRDs:v1.0.0'
        end
      end
  
      describe '#version' do
        it 'returns the versions specified in the resource descriptor' do
          resource_descriptor.version.should == 'v1.0.0'
        end
      end
    end
  end
end
