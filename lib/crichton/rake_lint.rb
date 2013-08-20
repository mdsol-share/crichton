require 'rails/railtie'

module Crichton
  class RakeLint < Rails::Railtie
    rake_tasks do
      require 'crichton/rake'
    end
  end
end