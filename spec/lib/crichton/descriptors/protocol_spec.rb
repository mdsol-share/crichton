require 'spec_helper'

module Crichton
  describe HttpDescriptor do
    let(:http_protocol) { drds_descriptor['protocols']['http'] }
    let(:http_descriptor) { http_protocol['list'] }
    let(:resource_descriptor) { mock('resource_descriptor') }
    let(:descriptor) { HttpDescriptor.new(resource_descriptor, http_descriptor, id: 'list') }
    
    before :all do
      %w(content_types headers method slt status_codes uri).all? { |type| http_descriptor[type] }.should be_true
    end

    describe '#content_types' do
      it 'returns the content_types' do
        descriptor.content_types.should == http_descriptor['content_types']
      end
    end

    describe '#headers' do
      it 'returns the headers' do
        descriptor.headers.should == http_descriptor['headers']
      end
    end

    describe '#method' do
      it 'returns the uniform interface method' do
        descriptor.method.should == http_descriptor['method']
      end
    end

    describe '#slt' do
      it 'returns the slt' do
        descriptor.slt.should == http_descriptor['slt']
      end
    end

    describe '#status_codes' do
      it 'returns the status_codes' do
        descriptor.status_codes.should == http_descriptor['status_codes']
      end
    end
    
    describe '#uri' do
      it 'returns the uri' do
        descriptor.uri.should == http_descriptor['uri']
      end
    end
  end
end
