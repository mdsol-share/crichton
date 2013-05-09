require 'spec_helper'

module Crichton
  module Descriptor
    describe TransitionDecorator do
      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { Resource.new(descriptor_document) }
      let(:descriptor) { resource_descriptor.semantics[@descriptor || 'drds'].transitions[@transition || 'list'] }
      let(:decorator) { TransitionDecorator.new(@target, descriptor, @options) }

      describe '#available?' do
        it 'returns true if the transition is available' do
          pending 'TODO'
        end

        it 'returns false if the transition is not available' do
          pending 'TODO'
        end
      end
      
      describe '#control?' do
        it 'returns true if the transition includes the semantics of a control' do
          pending 'TODO'
        end

        it 'returns false if the transition is not a control' do
          pending 'TODO'
        end
      end
      
      describe '#protocol' do
        context 'without :protocol option' do
          it 'returns the default protocol for the parent resource descriptor' do
            decorator.protocol.should == resource_descriptor.default_protocol
          end
          
          it 'raises an error if there is no default protocol defined for the resource descriptor' do
            descriptor_document['protocols'] = {}
            expect { decorator.protocol }.to raise_error(/No protocols defined for the resource descriptor DRDs.*/)
          end
        end

        context 'with :protocol option' do
          it 'returns the specified protocol' do
            @options = {protocol: 'option_protocol'}
            resource_descriptor.stub(:protocol_exists?).with('option_protocol').and_return(true)
            decorator.protocol.should == 'option_protocol'
          end
          
          it 'raises an error if the protocol is not defined for the parent resource descriptor' do
            @options = {protocol: 'bogus'}
            expect { decorator.protocol }.to raise_error(/^Unknown protocol bogus defined by options.*/)
          end
        end
      end

      describe '#protocol_descriptor' do
        it 'returns the protocol descriptor that details the implementation of the transition' do
          decorator.protocol_descriptor.should be_a(Http)
        end
        
        it 'returns nil if no protocol descriptor implements the transition for the transition protocol' do
          decorator.stub(:id).and_return('non-existent')
          decorator.protocol_descriptor.should be_nil
        end
      end

      describe '#source_defined?' do
        it 'returns true if the source of the transition details is defined' do
          pending 'TODO'
        end

        it 'returns false if the source of the transition details is not defined' do
          pending 'TODO'
        end
      end
      
      describe '#templated?' do
        it 'returns true if the transition URL requires template parameters' do
          pending 'TODO'
        end

        it 'returns false if the transition URL is not templated' do
          pending 'TODO'
        end
      end
      
      describe '#url' do
        it 'returns the fully qualified url for the transition' do
          pending 'TODO'
        end
      end
    end
  end
end
