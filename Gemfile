#####################################################################################
#
# Run `bundle exec appraisal install` on the command-line if you modify this file.
#
#####################################################################################

source 'https://rubygems.org'
gemspec

gem 'rails',         '~> 3.2.14'
gem 'debugger',      '~> 1.6.2'
gem 'debugger-xml',  '~> 0.3.3'
gem 'ruby-prof',     '~> 0.13'
gem 'yard',          '~> 0.8.7'
gem 'redcarpet',     '~> 3.0.0'
gem 'rake',          '~> 0.9'
gem 'awesome_print', '~> 1.1.0'

group :development, :test do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-nav'
end

group :test do
  gem 'sqlite3'
  gem 'yajl-ruby', '~> 1.2.0'
  gem 'faraday',   '~> 0.9.0'
  gem 'jquery-rails'
  gem 'nokogiri'
  gem 'launchy'
  gem 'webmock',        '~> 1.13.0'
  gem 'equivalent-xml', '~> 0.3.0'
  gem 'rspec',          '~> 2.14.0'
  gem 'rspec-rails'
  gem 'simplecov',      '~> 0.8'
  gem 'json_spec',      '~> 1.1.1'
  gem 'timecop',        '~> 0.7.1'
  #TODO: replace when fix for v1.0.0 will be released
  gem 'appraisal', git: 'https://github.com/thoughtbot/appraisal.git', ref: '7711d4d'
end
