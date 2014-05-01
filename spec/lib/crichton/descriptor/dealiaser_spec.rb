require 'spec_helper'
require 'crichton/descriptor/dealiaser'

module Crichton
  module Descriptor
    describe Dealiaser do
      before (:all) do
        @resource_descriptor = '
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
      - href: list'
      end

      let(:resource_descriptor) { YAML.load(@resource_descriptor) }
      let(:subject) { Dealiaser.dealias(resource_descriptor) }

      describe '#dealiase' do
        it 'dealiases document under descriptors tag' do
          subject.keys.should == ['descriptors']
        end

        it 'specifies type attribute for all dealiased elements' do
          [ 'total_count', 'list', 'update', 'create', 'drd' ].each do |type|
            subject['descriptors'][type].should have_key('type')
          end
        end

        it 'sets valid element type for semantic elements' do
          subject['descriptors']['total_count']['type'].should == 'semantic'
        end

        it 'sets valid element type for safe transitions' do
          subject['descriptors']['list']['type'].should == 'safe'
        end

        it 'sets valid element type for idempotent transitions' do
          subject['descriptors']['update']['type'].should == 'idempotent'
        end

        it 'sets valid element type for unsafe transitions' do
          subject['descriptors']['create']['type'].should == 'unsafe'
        end

        it 'sets valid element type for resources elements' do
          subject['descriptors']['drd']['type'].should == 'semantic'
        end

        it 'dealiases parameters tag into descriptors' do
          subject['descriptors']['update'].should have_key('descriptors')
        end

        it 'creates scope:uri key value for url parameters descriptors' do
          value = subject['descriptors']['update']['descriptors'].first
          value.should  include({ 'scope' => 'url' })
        end
      end
    end
  end
end
