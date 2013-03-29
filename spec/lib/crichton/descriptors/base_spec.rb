require 'spec_helper'

module Crichton
  module Descriptors
    describe Base do
      let(:descriptor_document) { basic_descriptor }
      let(:descriptor) { Base.new(descriptor_document, @options) }

      describe '#descriptor_document' do
        it 'returns the descriptor passed to the constructor' do
          descriptor.descriptor_document.should == descriptor_document
        end
      end

      describe '#doc' do
        it 'returns the descriptor description' do
          descriptor.doc.should == descriptor_document['doc']
        end
      end

      describe '#href' do
        it 'returns the href in the descriptor document' do
          descriptor.href.should == descriptor_document['href']
        end
      end

      describe '#id' do
        it 'returns the name of the descriptor' do
          descriptor.id.should == descriptor.name
        end
      end
      
      describe '#inspect' do
        it 'excludes the @descriptor_document ivar for readability' do
          descriptor.inspect.should_not =~ /.*@descriptor_document.*/
        end
      end

      describe '#name' do
        context 'with name in the descriptor document' do
          it 'returns the name of the descriptor as a string' do
            descriptor.name.should == descriptor_document['name']
          end
        end

        context 'with name in the options' do
          it 'returns the name of the descriptor as a string' do
            @options = {name: 'option_name'}
            descriptor.name.should == 'option_name'
          end
        end

        context 'with no name specified' do
          it 'returns nil' do
            descriptor = Base.new(basic_descriptor.reject { |k, _| k == 'name' })
            descriptor.name.should be_nil
          end
        end
      end

      describe '#rt' do
        it 'returns the descriptor return type' do
          descriptor.rt.should == descriptor_document['rt']
        end
      end

      describe '#sample' do
        it 'returns a sample value for the descriptor' do
          descriptor.sample.should == descriptor_document['sample']
        end
      end
      
      describe '#type' do
        it 'raise an error when not overridden by a subclass' do
          expect { descriptor.type }.to raise_error(RuntimeError,
            'The method #type is an abstract method that must be overridden in subclasses.')
        end
      end

      describe '#version' do
        it 'returns the descriptor version' do
          descriptor.version.should == descriptor_document['version']
        end
      end
    end
  end
end
