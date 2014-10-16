require 'spec_helper'
require 'rake'
require 'dice_bag/tasks'

describe Crichton do
  # before do
 #    Crichton.reset
 #    Crichton.clear_config
 #  end
 #
 #  # This restores the global setting - one of the tests sets this value to a generated value and that causes other
 #  # tests to fail later on - depending on the order of the tests.
 #  after do
 #
 #    Crichton.clear_config
 #    Crichton.reset
 #    Crichton.config_directory = CONF_DIR
 #
 #
 #  end
 #
 #  describe '.descriptor_registry' do
 #    it 'initializes the registry if the registry is not already initialized' do
 #      mock_registry = double('Registry')
 #      allow(mock_registry).to receive(:descriptor_registry)
 #      expect(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      Crichton.descriptor_registry
 #    end
 #
 #    it 'calls descriptor_registry on the registry' do
 #      mock_registry = double('Registry')
 #      expect(mock_registry).to receive(:descriptor_registry)
 #      allow(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      Crichton.descriptor_registry
 #    end
 #
 #    it 'returns descriptor_registry of the registry' do
 #      mock_registry = double('Registry')
 #      mock_descriptor_registry = double('descriptor_registry')
 #      allow(mock_registry).to receive(:descriptor_registry).and_return(mock_descriptor_registry)
 #      allow(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      expect(Crichton.descriptor_registry).to eq(mock_descriptor_registry)
 #    end
 #  end
 #
 #  describe '.raw_descriptor_registry' do
 #    it 'initializes the registry if the registry is not already initialized' do
 #      mock_registry = double('Registry')
 #      allow(mock_registry).to receive(:raw_descriptor_registry)
 #      expect(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      Crichton.raw_descriptor_registry
 #    end
 #
 #    it 'calls raw_descriptor_registry on the registry' do
 #      mock_registry = double('Registry')
 #      expect(mock_registry).to receive(:raw_descriptor_registry)
 #      allow(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      Crichton.raw_descriptor_registry
 #    end
 #
 #    it 'returns raw_descriptor_registry of the registry' do
 #      mock_registry = double('Registry')
 #      mock_descriptor_registry = double('raw_descriptor_registry')
 #      allow(mock_registry).to receive(:raw_descriptor_registry).and_return(mock_descriptor_registry)
 #      allow(Crichton::Registry).to receive(:new).and_return(mock_registry)
 #      expect(Crichton.raw_descriptor_registry).to eq(mock_descriptor_registry)
 #    end
 #  end
 #
 #  describe '.reset' do
 #    it 'clears any registered resource descriptors' do
 #      stub_alps_requests
 #      allow(Crichton).to receive(:descriptor_location).and_return(resource_descriptor_fixtures)
 #      registry_obj = double('Registry')
 #      allow(registry_obj).to receive(:descriptor_registry)
 #      allow(Crichton).to receive(:config_directory).and_return(File.join('spec', 'fixtures', 'config'))
 #      # Initializes registry
 #      Crichton.descriptor_registry
 #      # Clears registry
 #      Crichton.reset
 #      # Don't move this up - the first time around it should use the normal mechanism
 #      expect(Crichton::Registry).to receive(:new).and_return(registry_obj)
 #      # Initialize the registry - this being called indicates that the registry was empty.
 #      Crichton.descriptor_registry
 #    end
 #  end
 #
 #  describe '.config' do
 #    it 'raises an error if there is not crichton.yml configuration file' do
 #      Crichton.config_directory = 'non-existent'
 #      expect { Crichton.config }.to raise_error(RuntimeError,
 #        /^No crichton.yml file found in the configuration directory:.*/)
 #    end
 #
 #    it 'loads the crichton.yml file from the configuration directory' do
 #
 #      build_configuration_files(example_environment_config, SPECS_TEMP_DIR)
 #
 #      %w(alps deployment discovery documentation).each do |type|
 #        attribute = "#{type}_base_uri"
 #        expect(Crichton.config.send(attribute)).to eq(example_environment_config[attribute])
 #      end
 #    end
 #  end
 #
 #  describe '.config_directory' do
 #    it 'sets the path to the config directory' do
 #      Crichton.config_directory = 'path/to/config'
 #      expect(Crichton.config_directory).to eq('path/to/config')
 #    end
 #  end
 #
 #  describe '.config_file' do
 #    let(:file_path) { File.join(@root, 'config', 'crichton.yml') }
 #
 #    it 'returns the path to the crichton.yml file' do
 #      @root = Dir.pwd
 #      expect(Crichton.config_file).to eq(file_path)
 #    end
 #
 #    context 'when used in an Application' do
 #      before do
 #        @app = double('app')
 #      end
 #
 #      after do
 #        Crichton.clear_config
 #      end
 #
 #      context 'when Rails' do
 #        after do
 #          Object.send(:remove_const, :Rails) if Rails == @app
 #        end
 #
 #        it 'returns the config directory under the Rails root' do
 #          ::Rails = @app unless defined?(Rails)
 #          @root = 'rails_root'
 #
 #          allow(::Rails).to receive(:root).and_return(@root)
 #          expect(Crichton.config_file).to eq(file_path)
 #        end
 #      end
 #
 #      context 'when Sinatra' do
 #        after do
 #          Object.send(:remove_const, :Sinatra) if Sinatra == @app
 #        end
 #
 #        it 'returns the config directory under the Sinatra root' do
 #          ::Sinatra = @app unless defined?(Sinatra)
 #          @root = 'sinatra_root'
 #
 #          ::Sinatra.stub_chain(:settings, :root).and_return(@root)
 #          expect(Crichton.config_file).to eq(file_path)
 #        end
 #      end
 #    end
 #  end
 #
 #  describe '.descriptor_directory=' do
 #    it 'sets the descriptor directory' do
 #      Crichton.descriptor_directory = 'test_directory'
 #      expect(Crichton.descriptor_directory).to eq('test_directory')
 #    end
 #  end
 #
 #  describe '.register_drds_sample' do
 #    it 'initializes the registry with a sample resource descriptor document' do
 #      Crichton.register_drds_sample
 #      expect(Crichton.raw_descriptor_registry.keys).to eq(["drds", "drd"])
 #    end
 #  end
end

