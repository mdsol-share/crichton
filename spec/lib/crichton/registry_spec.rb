require 'spec_helper'

describe Crichton::Registry do
  let(:registry) { Crichton::Registry.new }
  let(:descriptor_filename) { "#{Dir.pwd}/spec/fixtures/resource_descriptors/drds_descriptor_v1.yml" }
  let(:errors_descriptor_filename) { "#{Dir.pwd}/spec/fixtures/resource_descriptors/errors_descriptor.yml" }
  
  context 'correctly registers resource descriptors' do
    it 'correctly registers resources descriptors from the default directory path' do
      expect(registry.resources_registry['DRDs'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
      expect(registry.resources_registry['Errors'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
    end
  
    it 'initializes with automatic_load set to false' do
      Crichton::Registry.should_not_receive(:register_multiple)
      @registry = Crichton::Registry.new(automatic_load: false)
      expect(@registry.resources_registry).to eq({})
    end

    it 'returns true for #registrations? if resources are correctly registered' do
      expect(registry.registrations?).to be_true
    end
  
    it 'returns correct #raw_descriptor_registry' do
      expect(registry.raw_descriptor_registry.keys).to eq(["drds", "drd", "errors"])
    end
  
    it 'returns correct #raw_profile_registry' do
      expect(registry.raw_profile_registry.keys).to eq(["DRDs", "Errors"])
    end
  end
  
  context '#load_resource_descriptor' do
    let(:registry) { Crichton::Registry.new }
    
    after do
      expect(registry.class).to eq(Crichton::Registry)
      expect(registry.resources_registry['DRDs'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
    end

    it 'registers filenames' do
      Crichton.stub(:descriptor_filenames).and_return([descriptor_filename])
    end
    
    it 'registers hash' do
      Crichton.stub(:descriptor_filenames).and_return([YAML.load_file(descriptor_filename)])
    end
  end
    
  context '#load_resource_descriptor with errors' do
  
    it 'raises error when the file does not exist' do
      Crichton.stub(:descriptor_filenames).and_return(['invalid_file.yml'])
      expect { Crichton::Registry.new }.to raise_error(ArgumentError, "Filename invalid_file.yml is not valid.")
    end
  
    it 'raises error when trying to register invalid type' do
      Crichton.stub(:descriptor_filenames).and_return([[]])
      expect { Crichton::Registry.new }.to raise_error(ArgumentError, "Document [] must be a String or a Hash.")
    end
  end
      
  context 'without autoload' do
    let(:registry) { Crichton::Registry.new(automatic_load: false) }

    it 'registers single resource' do
      resources_registry = registry.register_single(descriptor_filename)
      expect(resources_registry['DRDs'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
      expect(resources_registry['Errors']).to be_nil
    end
    
    it 'registers multiple resources' do
      resources_registry = registry.register_multiple([descriptor_filename, errors_descriptor_filename])
      expect(resources_registry['DRDs'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
      expect(resources_registry['Errors'].class).to eq(Crichton::Descriptor::ResourceDereferencer)
    end
  end
  
end