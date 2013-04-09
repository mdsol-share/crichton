require 'spec_helper'

module Crichton
  describe BaseSemanticDescriptor do
    let(:descriptor_document) { drds_descriptor }
    let(:descriptor) { BaseSemanticDescriptor.new(descriptor_document, @options) }

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
    
    describe '#links' do
      it 'returns an array of descriptor links' do
        descriptor.links.all? { |link| %(self help).include?(link.rel) }.should be_true
      end
    end

    describe '#id' do
      context 'with id in the descriptor document' do
        it 'returns the id of the descriptor as a string' do
          descriptor.id.should == descriptor_document['id']
        end
      end

      context 'with id in the options' do
        it 'returns the id of the descriptor as a string' do
          @options = {id: 'option_id'}
          descriptor.id.should == 'option_id'
        end
      end

      context 'with no id specified' do
        it 'returns nil' do
          descriptor = BaseDescriptor.new(drds_descriptor.reject { |k, _| k == 'id' })
          descriptor.id.should be_nil
        end
      end
    end
    
    describe '#inspect' do
      it 'excludes the @descriptor_document ivar for readability' do
        descriptor.inspect.should_not =~ /.*@descriptor_document=.*/
      end
    end

    describe '#name' do
      context 'with name in the descriptor document' do
        it 'returns the name of the descriptor as a string' do
          descriptor.name.should == descriptor_document['name']
        end
      end

      context 'with no name specified' do
        it 'returns nil' do
          descriptor = BaseSemanticDescriptor.new(drds_descriptor.reject { |k, _| k == 'name' })
          descriptor.name.should be_nil
        end
      end
    end

    describe '#type' do
      it 'raise an error when not overridden by a subclass' do
        expect { descriptor.type }.to raise_error(RuntimeError,
          'The method #type is an abstract method that must be overridden in subclasses.')
      end
    end
  end
end
