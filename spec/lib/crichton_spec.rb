require 'spec_helper'

describe Crichton do
  describe '.clear_registry' do
    before do
      Crichton.clear_registry
    end
  
    it 'clears any registered resource descriptors' do
      Crichton::ResourceDescriptor.register(drds_descriptor)
      Crichton.clear_registry
      Crichton::ResourceDescriptor.registry.should be_empty
    end
  end
  
  describe '.registry' do
    before do
      Crichton.clear_registry
    end
  
    context 'with a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(resource_descriptor_fixtures)
      end
  
      it 'loads resource descriptors from a resource descriptor directory if configured' do
        Crichton.registry.count.should == 2
      end
    end
  
    context 'without a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(nil)
      end
  
      it 'returns any manually registered resource descriptors' do
        descriptor = Crichton::ResourceDescriptor.register(drds_descriptor)
        Crichton.registry[descriptor.to_key].should == descriptor
      end
  
      it 'returns an empty hash if no resource descriptors are registered' do
        Crichton.registry.should be_empty
      end
    end
  end
end
                                                   
