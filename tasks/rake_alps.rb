require 'rails/railtie'

module Crichton
  class RakeAlps < Rails::Railtie
    rake_tasks do
      require 'crichton/rake'
    end
  end
end
