require 'spec_helper'
require 'crichton/descriptor/base'

module Crichton
  module Descriptor
    describe Base do
      let(:descriptor_document) { drds_descriptor }
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor) { Base.new(resource_descriptor, descriptor_document) }
  
      describe '#descriptor_document' do
        it 'returns the descriptor passed to the constructor' do
          expect(descriptor.descriptor_document).to eq(descriptor_document)
        end
      end
      
      describe '#doc' do
        it 'returns the descriptor return doc' do
          expect(descriptor.doc).to eq(descriptor_document['doc'])
        end
      end

      describe '#id' do
        it 'returns the descriptor id' do
          expect(descriptor.id).to eq(descriptor_document['id'])
        end
      end

      describe '#href' do
        it 'returns the href in the descriptor document' do
          descriptor_document['href'] = 'some_href'
          expect(descriptor.href).to eq(descriptor_document['href'])
        end
      end


      describe '#resource_descriptor' do
        it 'returns the parent resource_descriptor instance' do
          expect(descriptor.resource_descriptor).to eq(resource_descriptor)
        end
      end

      describe '#logger' do
        it 'allows access to the Crichton logger' do
          doubled_logger = double("logger")
          expect(Crichton).to receive(:logger).once.and_return(doubled_logger)
          expect(descriptor.logger).to eq(doubled_logger)
        end

        it 'memoizes the logger' do
          doubled_logger = double("logger")
          allow(Crichton).to receive(:logger).and_return(doubled_logger)
          memoized_logger = descriptor.logger
          expect(descriptor.logger.object_id).to eq(memoized_logger.object_id)
        end
      end

      describe '#name' do
        context 'without a name defined in the descriptor document' do
          it 'returns the id of the descriptor as a string' do
            expect(descriptor.name).to eq(descriptor_document['id'])
          end
        end

        context 'without a name defined in the descriptor document' do
          it 'returns the name of the descriptor as a string' do
            descriptor_document['name'] = 'name'
            expect(descriptor.name).to eq(descriptor_document['name'])
          end
        end
      end
      
      describe '#profile_link' do
        it 'returns the resource descriptor self link' do
          link = double('link')
          allow(resource_descriptor).to receive(:profile_link).and_return(link)
          expect(descriptor.profile_link).to eq(link)
        end
      end

      describe '#inspect' do
        it 'excludes the @descriptors ivar for readability' do
          expect(descriptor.inspect).not_to match(/.*@descriptors=.*/)
        end

        it 'excludes the @descriptor_document ivar for readability' do
          expect(descriptor.inspect).not_to match(/.*@descriptor_document=.*/)
        end

        it 'excludes the @resource_descriptor ivar for readability' do
          expect(descriptor.inspect).not_to match(/.*@resource_descriptor=.*/)
        end
      end
    end
  end
end
