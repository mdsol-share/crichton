require 'yaml'
require 'crichton'
require 'lint/base_validator'

module Lint
  class ProfileValidator < BaseValidator

    def initialize(registry)
       super(registry)
    end

    def validate()
       # looks for main missing properties
      add_to_errors('catastrophic.missing_main_id') unless top_level_resource.id
      add_to_warnings('profile.missing_version') unless top_level_resource.version
      add_to_errors('profile.missing_doc') unless top_level_resource.doc
      add_to_errors('profile.missing_self') unless top_level_resource.links['self'].href
      add_to_errors('profile.missing_help') unless top_level_resource.links['help'].href
    end

    def top_level_resource
      @top_resource ||= @registry[secondary_descriptor_keys.first].parent_descriptor
    end
  end
end
