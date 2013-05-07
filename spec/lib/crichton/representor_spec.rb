require 'spec_helper'

module Crichton
  describe Representor do
    let(:simple_test_class) do 
      resource_name = @resource_name
      Class.new do
        include Representor
        
        set_resource_name resource_name if resource_name
        
        def initialize(attributes)
          @attributes = attributes
        end
        
        attr_accessor :attributes
        
        # Use method missing/respond_to to mimic accessors
        def method_missing(method, *args, &block)
          (attributes && attributes.keys.include?(method.to_s)) ? attributes[method.to_s] : super
        end
        
        def respond_to?(method)
          (attributes && attributes.keys.include?(method)) ? true : super
        end
      end
    end
    
    context 'with associated class-level descriptors' do
      before do
        @resource_name = 'drds'
        register_descriptor(drds_descriptor)
      end
      
      describe '.data_semantic_descriptors' do
        it 'returns the filtered list of semantic data descriptors' do
          simple_test_class.data_semantic_descriptors.map(&:name).should == %w(total_count)
        end
      end

      describe '.embedded_semantic_descriptors' do
        it 'returns the filtered list of semantic embedded descriptors' do
          simple_test_class.embedded_semantic_descriptors.map(&:name).should == %w(items)
        end
      end

      describe '.link_transition_descriptors' do
        it 'returns the filtered list of link transition descriptors' do
          simple_test_class.link_transition_descriptors.first.name.should == 'list'
        end
      end

      describe '.embedded_transition_descriptors' do
        it 'returns the filtered list of embedded transition descriptors' do
          @resource_name = 'drd'
          simple_test_class.embedded_transition_descriptors.first.name.should == 'leviathan'
        end
      end
    end
      
    describe '.resource_descriptor' do
      it 'raises an error if no resource name has been defined for the class' do
        Crichton.stub(:registry).and_return({})
        expect { simple_test_class.resource_descriptor }.to raise_error(RuntimeError, 
          /^No resource name has been defined.*/)
      end
      
      it 'returns the resource descriptor registered with the resource name' do
        resource_descriptor = mock('resource_descriptor')
        @resource_name = 'resource'
        Crichton.stub(:registry).and_return(@resource_name => resource_descriptor)
        
        simple_test_class.resource_descriptor.should == resource_descriptor
      end
    end
    
    describe '.resource_name' do
      it 'raises an error if no resource name has been defined for the class' do
        expect { simple_test_class.resource_name }.to raise_error(RuntimeError, /^No resource name has been defined.*/)
      end
      
      it 'returns the resource name set on the base class' do
        @resource_name = :resource
        simple_test_class.resource_name.should == 'resource'
      end
    end

    context 'with_registered resource descriptor' do
      before do
        register_descriptor(drds_descriptor)
      end
      
      describe '#embedded_semantics' do
        it 'returns a hash of purely semantic attributes associated with the represented resource' do
          @resource_name = 'drds'
          item = mock('item')
          attributes = {'items' => [item]}
          representor = simple_test_class.new(attributes)
          representor.embedded_semantics.should == attributes
        end
      end
  
      describe '#data_semantics' do
        it 'returns a hash of purely semantic attributes associated with the represented resource' do
          @resource_name = 'drd'
          attributes = {'uuid' => 'representor_uuid', 'name' => 'representor'}
          representor = simple_test_class.new(attributes)
          representor.data_semantics.should == attributes
        end
      end
    end
  end
end
