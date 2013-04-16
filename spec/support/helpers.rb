module Support
  module Helpers
    def drds_descriptor
      YAML.load_file(drds_filename)
    end

    def drds_filename
      fixture_path('resource_descriptors', 'drds_descriptor_v1.yml')
    end

    def leviathans_descriptor
      YAML.load_file(leviathans_filename)
    end

    def leviathans_filename
      fixture_path('resource_descriptors', 'leviathans_descriptor_v1.yaml')
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
    
    private
    def fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end
  end
end
