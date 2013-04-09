require 'spec_helper'

module Crichton
  describe Descriptor do
    let(:descriptor_document) { drds_descriptor }
    let(:resource_descriptor) { mock('resource_descriptor') }
    let(:descriptor) { Descriptor.new(resource_descriptor, descriptor_document) }

    describe '#resource_descriptor' do
      it 'returns the parent resource_descriptor instance' do
        descriptor.resource_descriptor.should == resource_descriptor
      end
    end

    describe '#inspect' do
      it 'excludes the @resource_descriptor ivar for readability' do
        descriptor.inspect.should_not =~ /.*@resource_descriptor=.*/
      end
    end
  end
end
