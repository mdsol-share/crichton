require 'spec_helper'

describe Crichton do
  before do
    Crichton.clear_registry
    Crichton.clear_config
  end


  describe '.clear_registry' do
    it 'clears any registered resource descriptors' do
      Crichton::Descriptor::Resource.register(drds_descriptor)
      Crichton.clear_registry
      Crichton::Descriptor::Resource.registry.should be_empty
    end
  end
  
  describe '.config' do
    it 'raises an error if there is not crichton.yml configuration file' do
      Crichton.config_directory = 'non-existent'
      expect { Crichton.config }.to raise_error(RuntimeError,
        /^No crichton.yml file found in the configuration directory:.*/)
    end

    it 'loads the crichton.yml file from the configuration directory' do
      Crichton.config_directory = 'tmp'
      build_configuration_files(example_environment_config, 'tmp')
      
      %w(alps deployment discovery documentation).each do |type|
        attribute = "#{type}_base_uri"
        Crichton.config.send(attribute).should == example_environment_config[attribute]
      end
    end
  end
  
  describe '.config_directory' do
    it 'sets the path to the config directory' do
      Crichton.config_directory = 'path/to/config'
      Crichton.config_directory.should == 'path/to/config'
    end
  end
  
  describe '.config_file' do
    let(:file_path) { File.join(@root, 'config', 'crichton.yml') }
    
    it 'returns the path to the crichton.yml file' do
      @root = Dir.pwd
      Crichton.config_file.should == file_path
    end

    context 'when used in an Application' do
      before do
        @app = mock('app')
      end

      context 'when Rails' do
        after do
          Object.send(:remove_const, :Rails) if Rails == @app
        end

        it 'returns the config directory under the Rails root' do
          ::Rails = @app unless defined?(Rails)
          @root = 'rails_root'

          ::Rails.stub(:root).and_return(@root)
          Crichton.config_file.should == file_path
        end
      end

      context 'when Sinatra' do
        after do
          Object.send(:remove_const, :Sinatra) if Sinatra == @app
        end

        it 'returns the config directory under the Sinatra root' do
          ::Sinatra = @app unless defined?(Sinatra)
          @root = 'sinatra_root'
          
          ::Sinatra.stub_chain(:settings, :root).and_return(@root)
          Crichton.config_file.should == file_path
        end
      end
    end
  end
  
  describe '.registry' do
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
        descriptor = Crichton::Descriptor::Resource.register(drds_descriptor)
        Crichton.registry[descriptor.to_key].should == descriptor
      end
  
      it 'returns an empty hash if no resource descriptors are registered' do
        Crichton.registry.should be_empty
      end
    end
  end
end
                                                   
