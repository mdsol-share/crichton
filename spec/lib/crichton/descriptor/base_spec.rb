require 'spec_helper'
require 'crichton/descriptor/base'

module Crichton
  module Descriptor
    describe Base do
      let(:descriptor_document) { new_drds_descriptor }
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

      describe '#logger' do
        it 'allows access to the Crichton logger' do
          doubled_logger = double("logger")
          Crichton.should_receive(:logger).once.and_return(doubled_logger)
          descriptor.logger.should == doubled_logger
        end

        it 'memoizes the logger' do
          doubled_logger = double("logger")
          Crichton.stub(:logger).and_return(doubled_logger)
          memoized_logger = descriptor.logger
          descriptor.logger.object_id.should == memoized_logger.object_id
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
      
      describe '#profile_link' do
        it 'returns the resource descriptor self link' do
          link = mock('link')
          resource_descriptor.stub(:profile_link).and_return(link)
          descriptor.profile_link.should == link
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
