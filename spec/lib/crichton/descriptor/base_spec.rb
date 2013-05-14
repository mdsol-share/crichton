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
      
      describe '#doc' do
        it 'returns the descriptor return doc' do
          descriptor.doc.should == descriptor_document['doc']
        end
      end

      describe '#id' do
        it 'returns the descriptor id' do
          descriptor.id.should == descriptor_document['id']
        end
      end

      describe '#href' do
        it 'returns the href in the descriptor document' do
          descriptor_document['href'] = 'some_href'
          descriptor.href.should == descriptor_document['href']
        end
      end


      describe '#resource_descriptor' do
        it 'returns the parent resource_descriptor instance' do
          descriptor.resource_descriptor.should == resource_descriptor
        end
      end

      describe '#name' do
        context 'without a name defined in the descriptor document' do
          it 'returns the id of the descriptor as a string' do
            descriptor.name.should == descriptor_document['id']
          end
        end

        context 'without a name defined in the descriptor document' do
          it 'returns the name of the descriptor as a string' do
            descriptor_document['name'] = 'name'
            descriptor.name.should == descriptor_document['name']
          end
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
