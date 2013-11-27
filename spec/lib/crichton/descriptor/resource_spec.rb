require 'spec_helper'
require 'crichton/descriptor/resource'

module Crichton
  module Descriptor
    describe Resource do
      before do
        Crichton.clear_registry
      end

      describe '.new' do
        let(:descriptor) { Resource.new(drds_descriptor) }

        it 'returns a subclass of Profile' do
          descriptor.should be_a(Profile)
        end

        it_behaves_like 'a nested descriptor'
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
        it 'returns an absolute link' do
          resource_descriptor.profile_link.href.should == 'http://alps.example.com/DRDs'
        end

        it 'returns a link with the name profile' do
          resource_descriptor.profile_link.name.should == 'profile'
        end
      end

      describe '#help_link' do
        it 'returns an absolute link' do
          resource_descriptor.help_link.href.should == 'http://docs.example.org/Things/DRDs'
        end

        it 'returns a link with the name profile' do
          resource_descriptor.help_link.name.should == 'help'
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

      describe '.entry_points' do
        before do
          build_dir_for_lint_rspec('api_descriptors', 'fixtures/resource_descriptors')
          Crichton.stub(:descriptor_location).and_return('api_descriptors')
          Support::ALPSSchema::StubUrls.keys.each do |url|
            stub_request(:get, url).to_return(:status => 200, :headers => {})
          end
        end

        after do
          FileUtils.rm_rf('api_descriptors')
        end

        it 'returns a collection of entry points with valid attributes' do
          entry_point_collection = Crichton::Descriptor::Resource.entry_points
          entry_point_collection.should be_instance_of(Array)
          entry_point_collection.size.should == 2
          entry_point_collection.first[:rel].should == 'drds'
          entry_point_collection.first[:href].should == 'drds'
          entry_point_collection.last[:rel].should == 'leviathan'
          entry_point_collection.last[:href].should == 'leviathans/{uuid}'
        end
      end
    end
  end
end
