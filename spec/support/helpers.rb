module Support
  module Helpers
    def drds_descriptor
      YAML.load_file(drds_filename)
    end

    def drds_filename
      fixture_path('resource_descriptors', 'drds_descriptor_v1.yml')
    end
    
    def resource_descriptor_fixtures
      fixture_path('resource_descriptors')
    end
    
    private
    def fixture_path(*args)
      File.join(SPEC_DIR, 'fixtures', args)
    end
  end
end
