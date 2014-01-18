require 'spec_helper'
require 'rake'
require 'dice_bag/tasks'

describe Crichton do
  before do
    Crichton.clear_registry
    Crichton.clear_config
  end

  # This restores the global setting - one of the tests sets this value to a generated value and that causes other
  # tests to fail later on - depending on the order of the tests.
  after do
    Crichton::config_directory = File.join('spec', 'fixtures', 'config')
  end

  describe '.logger' do
    let(:logger) { double('logger') }

    after do
      Crichton.logger = nil
    end

    it 'sets a logger' do
      Crichton.logger = logger
      Crichton.logger.should == logger
    end

    context 'without Rails' do
      it 'returns a logger configured to STDOUT by default' do
        ::Logger.stub(:new).with(STDOUT).and_return(logger)
        Crichton.logger.should == logger
      end
    end

    context 'with Rails' do
      after do
        Object.send(:remove_const, :Rails)
      end

      it 'returns the Rails logger by default' do
        rails = double('Rails')
        rails.stub(:logger).and_return(logger)
        Object.const_set(:Rails, rails)

        Crichton.logger.should == logger
      end
    end
  end

  describe '.descriptor_registry' do
    it 'initializes the registry if the registry is not already initialized' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_registry.stub(:descriptor_registry)
      Crichton::Registry.should_receive(:new).and_return(mock_registry)
      Crichton.descriptor_registry
    end

    it 'calls descriptor_registry on the registry' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_registry.should_receive(:descriptor_registry)
      Crichton::Registry.stub(:new).and_return(mock_registry)
      Crichton.descriptor_registry
    end

    it 'returns descriptor_registry of the registry' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_descriptor_registry = mock('descriptor_registry')
      mock_registry.stub(:descriptor_registry).and_return(mock_descriptor_registry)
      Crichton::Registry.stub(:new).and_return(mock_registry)
      Crichton.descriptor_registry.should == mock_descriptor_registry
    end
  end

  describe '.raw_descriptor_registry' do
    it 'initializes the registry if the registry is not already initialized' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_registry.stub(:raw_descriptor_registry)
      Crichton::Registry.should_receive(:new).and_return(mock_registry)
      Crichton.raw_descriptor_registry
    end

    it 'calls raw_descriptor_registry on the registry' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_registry.should_receive(:raw_descriptor_registry)
      Crichton::Registry.stub(:new).and_return(mock_registry)
      Crichton.raw_descriptor_registry
    end

    it 'returns raw_descriptor_registry of the registry' do
      Crichton.clear_registry
      mock_registry = mock('Registry')
      mock_descriptor_registry = mock('raw_descriptor_registry')
      mock_registry.stub(:raw_descriptor_registry).and_return(mock_descriptor_registry)
      Crichton::Registry.stub(:new).and_return(mock_registry)
      Crichton.raw_descriptor_registry.should == mock_descriptor_registry
    end
  end

  describe '.clear_registry' do
    it 'clears any registered resource descriptors' do
      stub_alps_requests
      Crichton.stub(:descriptor_location).and_return(resource_descriptor_fixtures)
      registry_obj = mock('Registry')
      registry_obj.stub(:descriptor_registry)
      Crichton.stub(:config_directory).and_return(File.join('spec', 'fixtures', 'config'))
      # Initializes registry
      Crichton.descriptor_registry
      # Clears registry
      Crichton.clear_registry
      # Don't move this up - the first time around it should use the normal mechanism
      Crichton::Registry.should_receive(:new).and_return(registry_obj)
      # Initialize the registry - this being called indicates that the registry was empty.
      Crichton.descriptor_registry
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
      
      after do
        Crichton.clear_config
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

  describe '.descriptor_directory=' do
    it 'sets the descriptor directory' do
      Crichton.descriptor_directory = 'test_directory'
      Crichton.descriptor_directory.should == 'test_directory'
    end
  end
end
                                                   
