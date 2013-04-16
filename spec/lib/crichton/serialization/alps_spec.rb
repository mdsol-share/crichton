require 'spec_helper'

module Crichton
  module Serialization
    describe ALPS do
      class SimpleAlpsTestClass 
        include ALPS

        (ALPS_ATTRIBUTES | ALPS_ELEMENTS | %w(id links)).each do |property|
          next if property == 'link'
          define_method(property) do
            descriptor_document[property]
          end
        end
        
        alias :link :links

        define_method('descriptors') do
          (descriptor_document['descriptors'] || []).inject([]) do |a, descriptor|
            a << SimpleAlpsTestClass.new(descriptor)
          end
        end
        
        def initialize(descriptor_document)
          @descriptor_document = descriptor_document && descriptor_document.dup || {}
        end
        
        attr_reader :descriptor_document
      end
    
      let(:descriptor) { SimpleAlpsTestClass.new(leviathans_descriptor) }
      
      describe '#alps_attributes' do
        it 'returns a hash of alps descriptor attributes' do
          descriptor.alps_attributes.should == {'id' => 'Leviathans'}
        end
      end

      describe '#alps_descriptors' do
        it 'returns an array of alps descriptor hashes' do
          descriptor.alps_descriptors.map { |descriptor| descriptor['id'] }.should == %w(leviathan)
        end
      end

      describe '#alps_elements' do
        it 'returns a hash of alps descriptor elements' do
          descriptor.alps_elements.should == {
              'doc' => {'value' => 'Describes Leviathans.'},
              'ext' => [
                {'href' => 'alps_base/Leviathans#leviathan/alt', 'value' => 'Alternate.'}
              ],
              'link' => [
                  {'rel' => 'self', 'href' => 'alps_base/Leviathans'},
                  {'rel' => 'help', 'href' => 'documentation_base/Things/Leviathans'}
              ]
          }
        end
      end
    
      describe '#alps_hash' do
        context 'without options' do
          it 'returns a hash in an ALPS profile structure' do
            descriptor.alps_hash.should == alps_profile
          end
        end
        
        context 'with top_level option false' do
          it 'returns a hash in an ALPS descriptor structure' do
            descriptor.alps_hash(top_level: false)['alps'].should be_nil
          end
        end
      end
    end
  end
end
