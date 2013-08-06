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
          Resource.raw_registry.should be_empty
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
          it 'registers a the child detail descriptors by id in the registry' do
            resource_descriptor = Resource.register(@descriptor)

            resource_descriptor.descriptors.each do |descriptor|
              Resource.registry[descriptor.id].should == descriptor
            end
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
        
        it 'returns a hash of registered descriptor instances keyed by descriptor id' do
          resource_descriptor = Resource.register(drds_descriptor)

          resource_descriptor.descriptors.each do |descriptor|
            Resource.registry[descriptor.id].should == descriptor
          end
        end
      end
  
      describe '.raw_registry' do
        it 'returns an empty hash hash if no resource descriptors are registered' do
          Resource.raw_registry.should be_empty
        end

        it 'returns a hash of registered descriptor instances keyed by descriptor id' do
          resource_descriptor = Resource.register(drds_descriptor)

          resource_descriptor.descriptors.each do |descriptor|
            # Can't use a direct comparison as we don't get the original rescriptors returned when registering
            # but we can at least test that the names match.
            Resource.raw_registry[descriptor.id].name.should == descriptor.name
          end
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
      
      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { Resource.new(descriptor_document) }
      
      describe '#available_protocols' do
        it 'returns a list of available protocols' do
          resource_descriptor.available_protocols.should == %w(http)
        end
      end
      
      describe '#default_protocol' do
        it 'returns the top-level default protocol defined in the descriptor document' do
          descriptor_document['default_protocol'] = 'some_protocol'
          resource_descriptor.default_protocol.should == 'some_protocol'
        end

        it 'returns the first protocol define with no default protocol defined in the descriptor document' do
          resource_descriptor.default_protocol.should == 'http'
        end
        
        it 'raises an error if no protocols are defined and no default_protocol is defined' do
          descriptor_document['protocols'] = {}
          expect { resource_descriptor.default_protocol }.to raise_error(
            /^No protocols defined for the resource descriptor DRDs.*/)
        end
      end
      
      describe '#inspect' do
        it 'includes the @key ivar' do
          resource_descriptor.to_key
          resource_descriptor.inspect.should =~ /.*@key=.*/
        end
      end
      
      describe '#profile_link' do
        it 'returns a link with the name profile' do
          resource_descriptor.profile_link.name.should == 'profile'
        end
      end

      describe '#protocol_exists?' do
        it 'returns true if the protocol is defined in the descriptor document' do
          resource_descriptor.protocol_exists?('http').should be_true
        end

        it 'returns false if the protocol is not defined in the descriptor document' do
          resource_descriptor.protocol_exists?('bogus').should be_false
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
        
        it 'returns a hash of a hash of State instances' do
          resource_descriptor.states['drds']['collection'].should be_a(State)
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

      context 'with serialization' do
        let(:descriptor) { Resource.new(leviathans_descriptor) }

        it_behaves_like 'it serializes to ALPS'
      end
    end
  end
end
