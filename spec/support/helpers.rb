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
      Crichton.config_directory = template_path
      directory = File.join(DiceBag::Project.root, template_path)
      Dir::mkdir(directory) unless Dir.exists?(directory)

      # Remove existing crichton.yml from a previous run so overwrite confirmation doesn't appear.
      system("rm #{template_path}/crichton.yml") if File.exists?(File.join(directory, 'crichton.yml'))
      ::Rake::Task['config:generate_all'].invoke
      system("bundle exec rake config:file[\"#{template_path}/crichton.yml.dice\"] #{environment_args(env_vars)}")
    end

    def lint_rake_path
      tasks_path('lint.rake')
    end

    def drds_descriptor
      YAML.load_file(drds_filename)
    end

    def errors_descriptor
      YAML.load_file(errors_filename)
    end

    def create_drds_file(descriptor, filename, directory = SPECS_TEMP_DIR)
      path = temporary_drds_filepath(filename, directory)
      File.open(path, 'w') { |file| file.write descriptor.to_yaml }
      path
    end

    def temporary_drds_filepath(filename, directory)
      File.join(directory, filename)
    end

    def normalized_drds_descriptor
      Crichton.reset
      registry = Crichton::Registry.new(automatic_load: false)
      registry.register_single(drds_descriptor)
      resource_dereferencer = registry.resources_registry.values.first
      resource_dereferencer.dereference(registry.dereferenced_descriptors)
    end

    def register_drds_descriptor
      Crichton.reset
      Crichton.initialize_registry(drds_descriptor)
    end

    def drds_filename
      crichton_fixture_path('resource_descriptors', 'drds_descriptor_v1.yml')
    end

    def errors_filename
      crichton_fixture_path('resource_descriptors', 'errors_descriptor.yml')
    end

    def drds_non_existent_filename
      crichton_fixture_path('resource_descriptors', 'drds_descriptor_v1000.yml')
    end

    def drds_hal_json
      @drds_hal_json ||= File.open(crichton_fixture_path('hal.json'))
    end

    def drds_hale_json
      @drds_hal_json ||= File.open(crichton_fixture_path('naive_hale.json'))
    end

    def drds_microdata_html
      @drds_microdata_html ||= Nokogiri::XML(File.open(crichton_fixture_path('drds_microdata.html')))
    end

    def drds_styled_microdata_html
      @drds_styled_microdata_html ||= Nokogiri::XML(File.open(crichton_fixture_path('drds_styled_microdata.html')))
    end

    def drds_styled_microdata_embed_html
      @drds_styled_embed_microdata_html ||= Nokogiri::XML(File.open(crichton_fixture_path('drds_styled_microdata_embed.html')))
    end

    def example_environment_config
      config = %w(alps deployment discovery documentation crichton_proxy).inject({}) do |h, attribute|
        h["#{attribute}_base_uri"] = "http://#{attribute}.example.org"; h
      end
      config['crichton_proxy_base_uri'] = 'http://example.org/crichton'
      config['css_uri'] = 'http://example.org/resources/css.css'
      config['js_uri'] = 'http://example.org/resources/js.js'
      config['resources_catalog_response_expiry'] = 40
      config['alps_profile_response_expiry'] = 40
      config['use_alps_middleware'] = true
      config['use_discovery_middleware'] = true
      config['service_level_target_header'] = 'CONFIGURED_SLT_HEADER'
      config['external_documents_cache_directory'] = 'tmp/not/the/default'
      config['external_documents_store_directory'] = 'tmp/also/not/the/default'
      config
    end

    def leviathans_descriptor
      YAML.load_file(leviathans_filename)
    end

    def leviathans_filename
      crichton_fixture_path('resource_descriptors', 'leviathans_descriptor_v1.yaml')
    end

    def stub_example_configuration
      allow(Crichton).to receive(:config).and_return(Crichton::Configuration.new(example_environment_config))
    end

    def resource_descriptor_fixtures
      crichton_fixture_path('resource_descriptors')
    end

    shared_examples_for 'a nested descriptor' do
      it 'responds to descriptors' do
        expect(descriptor).to respond_to(:semantics)
      end

      it 'responds to semantics' do
        expect(descriptor).to respond_to(:semantics)
      end

      it 'responds to transitions' do
        expect(descriptor).to respond_to(:transitions)
      end
    end

    def load_lint_translation_file
      I18n.load_path = [File.join(LINT_DIR, 'en.yml')]
      I18n.default_locale = 'en'
      I18n.reload!
    end

    def expected_output(error_or_warning, key, options = {})
      generate_lint_file_line(options[:filename]) <<
        generate_section_header(options[:section])  <<
        generate_sub_header(options[:sub_header]) <<
        build_colorized_lint_output(error_or_warning, key, options) << "\t\n"
    end

    def build_colorized_lint_output(error_or_warning, key, options = {})
      I18n.t(key, options).send(error_or_warning == :error ? :red : :yellow)
    end

    private
    def generate_lint_file_line(filename)
      filename ? "In file '#{filename}':\n" : ""
    end

    def generate_section_header(section)
      return "" if section == :catastrophic
      section ? "\n#{section.capitalize} Section:" << "\n" : ""
    end

    def generate_sub_header(sub_header)
      return "  " if sub_header.nil?
      sub_header == :error ? "ERRORS:".red << "\n  " : "WARNINGS:".yellow << "\n  "
    end

    def environment_args(env_vars)
      env_vars.inject('') { |s, (k, v)| s << "#{k.upcase}=#{v} " }
    end

    def crichton_fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end

    def alps_fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', 'alps', args)
    end

    def alps_json_data
      File.open(alps_fixture_path('DRDs.json'), 'rb') { |f| f.read }
    end

    def tasks_path(*args)
      File.join(Dir.pwd, 'tasks', args)
    end

    def build_dir_for_lint_rspec(config_dir, files_to_copy)
      FileUtils.rm_rf(config_dir) unless Dir[config_dir].empty?  # Dir always returns an array
      FileUtils.copy_entry(File.expand_path("../#{files_to_copy}", File.dirname(__FILE__)), config_dir)
    end

    alias :copy_resource_to_config_dir :build_dir_for_lint_rspec

    def stub_configured_profiles
      copy_resource_to_config_dir('api_descriptors', 'fixtures/resource_descriptors')
      FileUtils.rm_rf('api_descriptors/leviathans_descriptor_v1.yaml')
    end

    def stub_crichton_config_for_rdlint
      copy_resource_to_config_dir('config', 'fixtures/config')
    end

    def clear_crichton_config_dir
      FileUtils.rm_rf('config')
    end

    def clear_configured_profiles
      FileUtils.rm_rf('api_descriptors')
    end

    def stub_alps_requests
      Support::ALPSSchema::StubUrls.each do |url, body|
        stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
      end
    end
    
    # Used in linter specs to run descriptor documents through lint
    def validation_report(file)
      capture(:stdout) { validator.validate(file) }
    end
    
    def crichton_register_sample(sample_filename)
      Crichton.initialize_registry(sample_filename)
    end
    
    def assert_file(relative_path, regexp)
      expect(File.exists?(relative_path)).to be true
      read = File.read(relative_path)
      expect(read).to match(regexp)
    end
  end
end
