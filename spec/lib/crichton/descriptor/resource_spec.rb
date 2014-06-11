require 'spec_helper'
require 'crichton/descriptor/resource'

module Crichton
  module Descriptor
    describe Resource do
      describe '.new' do
        let(:descriptor) { Resource.new(drds_descriptor) }
  
        it 'returns a subclass of Profile' do
          expect(descriptor).to be_a(Profile)
        end
        
        it_behaves_like 'a nested descriptor'
      end
  

      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { Resource.new(ResourceDereferencer.new(descriptor_document).dealiased_document) }
      
      describe '#available_protocols' do
        it 'returns a list of available protocols' do
          expect(resource_descriptor.available_protocols).to eq(%w(http))
        end
      end
      
      describe '#default_protocol' do
        #TODO: this needs to be revisited: our convention is protocolname_protocol, which de-aliases
        # in protocols => { default => ... } which is wrong.
        # it 'returns the top-level default protocol defined in the descriptor document' do
        #   descriptor_document['default_protocol'] = 'some_protocol'
        #   resource_descriptor.default_protocol.should == 'some_protocol'
        # end

        it 'returns the first protocol define with no default protocol defined in the descriptor document' do
          expect(resource_descriptor.default_protocol).to eq('http')
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
          expect(resource_descriptor.inspect).to match(/.*@key=.*/)
        end
      end
      
      describe '#profile_link' do
        it 'returns an absolute link' do
          expect(resource_descriptor.profile_link.href).to eq('http://alps.example.com/DRDs')
        end

        it 'returns a link with the name profile' do
          expect(resource_descriptor.profile_link.name).to eq('profile')
        end
      end

      describe '#help_link' do
        it 'returns an absolute link' do
          expect(resource_descriptor.help_link.href).to eq('http://docs.example.org/Things/DRDs')
        end

        it 'returns a link with the name profile' do
          expect(resource_descriptor.help_link.name).to eq('help')
        end
      end

      describe '#protocol_exists?' do
        it 'returns true if the protocol is defined in the descriptor document' do
          expect(resource_descriptor.protocol_exists?('http')).to be_true
        end

        it 'returns false if the protocol is not defined in the descriptor document' do
          expect(resource_descriptor.protocol_exists?('bogus')).to be_false
        end
      end
      
      describe '#protocols' do
        it 'returns a hash protocol-specific transition descriptors keyed by protocol' do
          expect(resource_descriptor.protocols['http']).to_not be_empty
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
          expect(resource_descriptor.protocol_transition('http', 'list')).to be_instance_of(Http)
        end
      end

      describe '#states' do
        it 'returns as hash of state descriptors keyed by resource' do
          expect(resource_descriptor.states['drds']).to_not be_empty
        end
        
        it 'returns a hash of a hash of State instances' do
          expect(resource_descriptor.states['drds']['collection']).to be_instance_of(State)
        end
      end
  
      describe '#to_key' do
        it 'returns a key from the ID and version of the resource descriptor' do
          expect(resource_descriptor.to_key).to eq('DRDs')
        end
      end
    end
  end
end
