require 'colorize'

module Support
  module Helpers

    def build_sample_serializer(name)
      type = name.to_s.gsub(/(\d+|Serializer$)/, '').underscore.to_sym
      sample_serializer = <<-SAMPLE
      class #{name} < Crichton::Representor::Serializer
        media_types #{type}: %w(application/#{type}), other_#{type}: %w(application/other_#{type})
      end
      SAMPLE
      sample_serializer
    end

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
      Crichton.initialize_registry(drds_descriptor)
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
      config = %w(alps deployment discovery documentation).inject({}) do |h, attribute|
        h["#{attribute}_base_uri"] = "http://#{attribute}.example.org"; h
      end
      config['css_uri'] = 'http://example.org/resources/styles.css'
      config
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
              descriptor.to_alps_hash.should == alps_profile_with_absolute_links
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
              JSON.parse(descriptor.to_json).should == alps_profile_with_absolute_links
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

    def lint_spec_filename(*args)
      folder, filename = args.count == 1 ? ['', args.first] : args
      fixture_path('lint_resource_descriptors', folder, filename)
    end

    def load_lint_translation_file
      I18n.load_path = [File.join(LINT_DIR, 'eng.yml')]
      I18n.default_locale = 'eng'
    end

    def expected_output(error_or_warning, key, options = {})
      (generate_lint_file_line(options[:filename]) << (error_or_warning == :error ?
        "\tERROR: ".red : "\tWARNING: ".yellow) << build_colorized_lint_output(error_or_warning, key, options) << "\n")
    end

    private
    def generate_lint_file_line(filename)
      filename ? "In file '#{filename}':\n" : ""
    end

    def environment_args(env_vars)
      env_vars.inject('') { |s, (k, v)| s << "#{k.upcase}=#{v} " }
    end

    def fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end

    def default_lint_descriptor_file(file)
      File.join(Crichton.descriptor_location, file)
    end

    def build_colorized_lint_output(error_or_warning, key, options = {})
      I18n.t(key, options).send(error_or_warning == :error ? :red : :yellow)
    end

    def build_dir_for_lint_rspec(config_dir, files_to_copy)
      FileUtils.rm_rf(config_dir) unless Dir[config_dir].empty?  # Dir always returns an array
      FileUtils.copy_entry(File.expand_path("../#{files_to_copy}", File.dirname(__FILE__)), config_dir)
    end
  end
end
