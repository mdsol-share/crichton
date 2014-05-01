require 'spec_helper'
require 'crichton/descriptor/descriptor_element'

module Crichton
  module Descriptor
    describe DescriptorElement do
      let(:registry) { { 'DRDs#name' => @descriptor_element } }
      let(:subject) { DescriptorElement.new('DRDs', 'name', @descriptor_element ) }

      describe '#initialize' do
        before do
          @descriptor_element =
            { 'doc' => 'The name of DRD',
              'href' => 'http://alps.io/schema.org/Text'
            }
        end

        it 'returns the descriptor_element passed to constructor' do
          expect(subject.descriptor_document).to eq(@descriptor_element)
        end

        it 'returns descriptor id passed to constructor' do
          expect(subject.descriptor_id).to eq('name')
        end

        it 'returns document id passed to constructor' do
          expect(subject.document_id).to eq('DRDs')
        end
      end

      describe '#descriptor_options' do
        it 'returns empty hash if no options found in descriptor element' do
          @descriptor_element = {}
          expect(subject.descriptor_options).to eq({})
        end

        it 'registers available options found in descriptor element' do
          @descriptor_element =
          { 'doc' => 'The name of DRD',
            'href' => 'http://alps.io/schema.org/Integer',
            'options' => { 'id' => 'name_list', 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options.keys).to eq([ 'DRDs#name_list' ])
        end

        it 'returns empty hash if options doesnt have id' do
          @descriptor_element =
          { 'doc' => 'The name of DRD',
            'href' => 'http://alps.io/schema.org/Integer',
            'options' => { 'list' => ['samplename','drdname'] }
          }
          expect(subject.descriptor_options).to eq({})
        end
      end
    end
  end
end
