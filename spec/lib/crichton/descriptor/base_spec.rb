require 'spec_helper'

module Crichton
  module Descriptor
    describe Base do
      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { mock('resource_descriptor') }
      let(:descriptor) { Base.new(resource_descriptor, descriptor_document) }
  
      describe '#descriptor_document' do
        it 'returns the descriptor passed to the constructor' do
          descriptor.descriptor_document.should == descriptor_document
        end
      end

      describe '#resource_descriptor' do
        it 'returns the parent resource_descriptor instance' do
          descriptor.resource_descriptor.should == resource_descriptor
        end
      end
      
      describe '#inspect' do
        it 'excludes the @descriptors ivar for readability' do
          descriptor.inspect.should_not =~ /.*@descriptors=.*/
        end

        it 'excludes the @descriptor_document ivar for readability' do
          descriptor.inspect.should_not =~ /.*@descriptor_document=.*/
        end

        it 'excludes the @resource_descriptor ivar for readability' do
          descriptor.inspect.should_not =~ /.*@resource_descriptor=.*/
        end
      end
    end
  end
end
