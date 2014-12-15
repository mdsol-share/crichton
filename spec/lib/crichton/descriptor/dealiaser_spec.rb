require 'spec_helper'
require 'crichton/descriptor/dealiaser'

module Crichton
  module Descriptor
    describe Dealiaser do
      let(:resource_descriptor) { YAML.load(@resource_descriptor) }
      let(:subject) { Dealiaser.dealias(resource_descriptor) }

      describe '#dealias' do
        shared_examples_for 'dealiased document' do
          it 'returns empty hash when resource descriptor has no keywords' do
            subject = Dealiaser.dealias({})
            expect(subject).to eq({})
          end

          it 'dealiases document under descriptors tag' do
            expect(subject.keys).to eq(['descriptors'])
          end

          it 'specifies type attribute for all dealiased elements' do
            properties =  %w(total_count list update create drd)
            expect(properties.all? { |property| subject['descriptors'][property].include?('type') }).to be true
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
        end

        context 'when semantics tag' do
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

          it 'creates scope:uri key value for url parameters descriptors' do
            value = subject['descriptors']['update']['descriptors'].first
            expect(value).to include({ 'scope' => 'url' })
          end

          it_behaves_like 'dealiased document'
        end

        context 'when data tag is top-level tag' do
          before(:all) do
            @resource_descriptor = <<-DESCRIPTOR
              data:
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

          it 'creates scope:uri key value for url parameters descriptors' do
            value = subject['descriptors']['update']['descriptors'].first
            expect(value).to include({ 'scope' => 'url' })
          end

          it_behaves_like 'dealiased document'
        end

        context 'when data tag is not top-level tag' do
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
                  data:
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

          it_behaves_like 'dealiased document'
        end

        context 'when both semantics and data tags are used' do
          before(:all) do
            @resource_descriptor = <<-DESCRIPTOR
              data:
                total_count:
                  doc: The total count of DRDs.
                  href: http://alps.io/schema.org/Integer
                  sample: 1
              semantics:
                name:
                  doc: The name of the DRD.
                  href: http://alps.io/schema.org/Text
                  sample: drdname
              safe:
                list:
                  doc: Returns a list of DRDs.
                  name: self
                  rt: drds
              idempotent:
                update:
                  semantics:
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

          it 'dealiases elements under top-level descriptors tag' do
            expect(subject['descriptors'].keys).to include('name', 'total_count')
          end

          it_behaves_like 'dealiased document'
        end
      end
    end
  end
end
