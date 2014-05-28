require 'crichton/middleware/registry_cleaner'
module Crichton
  class Railtie < Rails::Railtie
    initializer "crichton.insert_middleware" do |app|
      app.config.middleware.use "Crichton::Middleware::RegistryCleaner"
    end
  end
end