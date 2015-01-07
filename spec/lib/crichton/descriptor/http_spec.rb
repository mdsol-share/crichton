require 'spec_helper'
require 'crichton/descriptor/http'

module Crichton
  module Descriptor
    describe Http do
      let(:http_protocol) { normalized_drds_descriptor['protocols']['http'] }
      let(:http_descriptor) { http_protocol[@protocol_transition || 'list'] }
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor) { Http.new(resource_descriptor, http_descriptor, @protocol_transition) }

      before :each do
        list_descriptor = normalized_drds_descriptor['protocols']['http']['list']
        expect(%w(headers method slt uri).all? { |type| list_descriptor[type] }).to be true
      end

      describe '#headers' do
        it 'returns the headers' do
          expect(descriptor.headers).to eq(http_descriptor['headers'])
        end
      end

      describe '#interface_method' do
        context 'when uri_source is requested' do
          it 'returns GET as uniform interface method' do
            @protocol_transition = 'leviathan-link'
            expect(descriptor.interface_method).to eq('GET')
          end
        end

        it 'returns the uniform interface method' do
          expect(descriptor.interface_method).to eq(http_descriptor['method'])
        end
      end

      describe '#slt' do
        it 'returns the slt' do
          expect(descriptor.slt).to eq(http_descriptor['slt'])
        end
      end

      describe '#uri' do
        it 'returns the uri' do
          expect(descriptor.uri).to eq(http_descriptor['uri'])
        end
      end

      describe '#uri_source' do
        it 'returns the source method associated with the uri' do
          @protocol_transition = 'leviathan-link'
          expect(descriptor.uri_source).to eq(http_descriptor['uri_source'])
        end
      end

      describe '#url_for' do
        let(:deployment_base_uri) { 'http://deployment.example.org' }
        let(:target) { double('target') }

        before do
          config = Crichton::Configuration.new({'deployment_base_uri' => deployment_base_uri})
          allow(Crichton).to receive(:config).and_return(config)
        end

        context 'with parameterized uri' do
          before do
            @protocol_transition = 'activate'
          end

          it 'returns the uri populated from the target attributes' do
            allow(target).to receive(:uuid).and_return('some_uuid')
            expect(descriptor.url_for(target)).to match(/#{deployment_base_uri}\/drds\/some_uuid\/activate/)
          end

          it 'raises an error if the target does not implement a uri parameter' do
            expect { descriptor.url_for(target) }.to raise_error(ArgumentError,
              /^The target .* does not implement the template variable\(s\) 'uuid'.*/)
          end
        end

        context 'without parameterized uri' do
          it 'returns the uri as a url' do
            expect(descriptor.url_for(target)).to match(/#{deployment_base_uri}\/drds/)
          end
        end

        context 'with embedded transition' do
          it 'returns the url associated with the source method' do
            @protocol_transition = 'leviathan-link'
            url = double('url')
            allow(target).to receive(descriptor.uri_source).and_return(url)

            expect(descriptor.url_for(target)).to eq(url)
          end
        end

        it 'logs a warning in case of no configured URL' do
          allow(descriptor).to receive(:uri).and_return(nil)
          allow(descriptor).to receive(:uri_source).and_return(:junk)
          logger = double(:logger)
          allow(descriptor).to receive(:logger).and_return(logger)
          expect(logger).to receive(:warn)
          descriptor.url_for(target)
        end
      end
    end
  end
end
