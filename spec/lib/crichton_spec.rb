require 'spec_helper'

describe Crichton do
  describe '.clear_resource_descriptors' do
    before do
      Crichton.clear_resource_descriptors
    end
  
    it 'clears any registered resource descriptors' do
      Crichton::Descriptors::Resource.register(drds_descriptor)
      Crichton.clear_resource_descriptors
      Crichton::Descriptors::Resource.registered_resources.should be_empty
    end
  end
  
  describe '.resource_descriptors' do
    before do
      Crichton.clear_resource_descriptors
    end
  
    context 'with a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(resource_descriptor_fixtures)
      end
  
      it 'loads resource descriptors from a resource descriptor directory if configured' do
        Crichton.resource_descriptors.count.should == 2
      end
    end
  
    context 'without a directory of resource descriptors specified' do
      before do
        Crichton.stub_chain(:config, :resource_descriptors_location).and_return(nil)
      end
  
      it 'returns any manually registered resource descriptors' do
        descriptor = Crichton::Descriptors::Resource.register(drds_descriptor)
        Crichton.resource_descriptors[descriptor.id].should == descriptor
      end
  
      it 'returns an empty hash if no resource descriptors are registered' do
        Crichton.resource_descriptors.should be_empty
      end
    end
  end
end
                                                   
