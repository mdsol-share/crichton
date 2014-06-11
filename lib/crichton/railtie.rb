require 'crichton/helpers'
require 'crichton/middleware/registry_cleaner'
require 'crichton/middleware/alps_profile_response'
require 'crichton/middleware/resource_home_response'

module Crichton
  class Railtie < Rails::Railtie
    include Crichton::Helpers::ConfigHelper

    initializer "crichton.insert_middleware" do |app|
      app.config.middleware.use "Crichton::Middleware::RegistryCleaner" if Rails.env.development?
      if config.include_discovery_middleware?
        app.config.middleware.use "Crichton::Middleware::ResourceHomeResponse", config.resource_home_response_expiry
      end
      if config.include_alps_middleware?
        app.config.middleware.use "Crichton::Middleware::AlpsProfileResponse", config.alps_profile_response_expiry
      end
    end
  end
end
