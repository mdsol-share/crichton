require 'crichton/helpers'
require 'crichton/middleware/registry_cleaner'
require 'crichton/middleware/alps_profile_response'
require 'crichton/middleware/service_resource_catalog'

module Crichton
  class Railtie < Rails::Railtie
    include Crichton::Helpers::ConfigHelper

    initializer "crichton.insert_middleware" do |app|
      app.config.middleware.use "Crichton::Middleware::RegistryCleaner" if Rails.env.development?
      if config.use_discovery_middleware?
        app.config.middleware.use "Crichton::Middleware::ServiceResourceCatalog", config.resources_catalog_response_expiry
      end
      if config.use_alps_middleware?
        app.config.middleware.use "Crichton::Middleware::AlpsProfileResponse", config.alps_profile_response_expiry
      end
    end
  end
end
