require 'spec_helper'
require 'crichton/descriptor/dealiaser'

module Crichton
  module Descriptor
    describe Dealiaser do
      before(:all) do
        @resource_descriptor = <<-DESCRIPTOR
          semantics:
            total_count:
              doc: The total count of DRDs.
              href: http://alps.io/schema.org/Integer
              sample: 1
          safe:
            list:
              doc: Returns a list of DRDs.
              name: self
              rt: drds
          idempotent:
            update:
              parameters:
                - href: name
          unsafe:
            create:
              descriptors:
                - href: name
          resources:
            drd:
              descriptors:
                - href: name
                - href: list
        DESCRIPTOR
      end

      let(:resource_descriptor) { YAML.load(@resource_descriptor) }
      let(:subject) { Dealiaser.dealias(resource_descriptor) }

      describe '#dealias' do
        it 'returns empty hash when resource descriptor has no keywords' do
          subject = Dealiaser.dealias({})
          expect(subject).to eq({})
        end

        it 'dealiases document under descriptors tag' do
          expect(subject.keys).to eq(['descriptors'])
        end

        it 'specifies type attribute for all dealiased elements' do
          properties =  %w(total_count list update create drd)
          expect(properties.all? { |property| subject['descriptors'][property].include?('type') }).to be_true
        end

        it 'sets valid element type for semantic elements' do
          expect(subject['descriptors']['total_count']['type']).to eq('semantic')
        end

        it 'sets valid element type for safe transitions' do
          expect(subject['descriptors']['list']['type']).to eq('safe')
        end

        it 'sets valid element type for idempotent transitions' do
          expect(subject['descriptors']['update']['type']).to eq('idempotent')
        end

        it 'sets valid element type for unsafe transitions' do
          expect(subject['descriptors']['create']['type']).to eq('unsafe')
        end

        it 'sets valid element type for resources elements' do
          expect(subject['descriptors']['drd']['type']).to eq('semantic')
        end

        it 'dealiases parameters tag into descriptors' do
          expect(subject['descriptors']['update']).to have_key('descriptors')
        end

        it 'creates scope:uri key value for url parameters descriptors' do
          value = subject['descriptors']['update']['descriptors'].first
          expect(value).to include({ 'scope' => 'url' })
        end
      end
    end
  end
end
