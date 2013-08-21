module Support
  module Helpers
    def build_configuration_files(env_vars, template_path)
      directory = File.join(DiceBag::Project.root, template_path)
      Dir::mkdir(directory) unless Dir.exists?(directory)

      # Remove existing crichton.yml from a previous run so overwrite confirmation doesn't appear.
      system("rm #{template_path}/crichton.yml") if File.exists?(File.join(directory, 'crichton.yml'))

      ::Rake::Task['config:generate_all'].invoke
      system("bundle exec rake config:file[\"#{template_path}/crichton.yml.dice\"] #{environment_args(env_vars)}")
    end

    def drds_descriptor
      YAML.load_file(drds_filename)
    end
    
    def register_drds_descriptor
      Crichton.clear_registry
      Crichton::Descriptor::Resource.register(drds_descriptor)
      Crichton::Descriptor::Resource.dereference_queued_descriptor_hashes_and_build_registry
    end

    def drds_filename
      fixture_path('resource_descriptors', 'drds_descriptor_v1.yml')
    end

    def drds_microdata_html
      @drds_microdata_html ||= Nokogiri::XML(File.open(fixture_path('drds_microdata.html')))
    end

    def drds_styled_microdata_html
      @drds_styled__microdata_html ||= Nokogiri::XML(File.open(fixture_path('drds_styled_microdata.html')))
    end
    
    def example_environment_config
      %w(alps deployment discovery documentation).inject({}) do |h, attribute|
        h["#{attribute}_base_uri"] = "http://#{attribute}.example.org"; h
      end
    end

    def leviathans_descriptor
      YAML.load_file(leviathans_filename)
    end

    def leviathans_filename
      fixture_path('resource_descriptors', 'leviathans_descriptor_v1.yaml')
    end
    
    def stub_example_configuration
      Crichton.stub(:config).and_return(Crichton::Configuration.new(example_environment_config))
    end
    
    def register_descriptor(descriptor)
      Crichton.clear_registry
      Crichton::Descriptor::Resource.register(descriptor)
      Crichton::Descriptor::Resource.dereference_queued_descriptor_hashes_and_build_registry
    end

    def resource_descriptor_fixtures
      fixture_path('resource_descriptors')
    end

    shared_examples_for 'a nested descriptor' do
      it 'responds to descriptors' do
        descriptor.should respond_to(:semantics)
      end

      it 'responds to semantics' do
        descriptor.should respond_to(:semantics)
      end

      it 'responds to transitions' do
        descriptor.should respond_to(:transitions)
      end
    end
    
    shared_examples_for 'it serializes to ALPS' do
      context 'when hash' do
        describe '#to_alps_hash' do
          context 'without options' do
            it 'returns a hash in an ALPS profile structure' do
              descriptor.to_alps_hash.should == alps_profile
            end
          end
  
          context 'with top_level option false' do
            it 'returns a hash in an ALPS descriptor structure' do
              descriptor.to_alps_hash(top_level: false)['alps'].should be_nil
            end
          end
        end
      end
      
      context 'when JSON' do
        describe '#to_json' do
          context 'without options' do
            it 'returns a JSON ALPS profile structure' do
              JSON.parse(descriptor.to_json).should == alps_profile
            end
          end
  
          context 'with pretty option true' do
            it 'returns a json alps profile pretty-formatted' do
              MultiJson.should_receive(:dump).with(descriptor.to_alps_hash, pretty: true)
              descriptor.to_json(pretty: true)
            end
          end
        end
      end
      
      context 'when XML' do
        it 'returns an XML ALPS profile structure' do
          descriptor.to_xml.should be_equivalent_to(alps_xml)
        end
      end
    end
    
    private
    def environment_args(env_vars)
      env_vars.inject('') { |s, (k, v)| s << "#{k.upcase}=#{v} " }
    end

    def fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end
  end
end
