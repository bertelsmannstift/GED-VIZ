# -*- coding: utf-8 -*-
source 'https://rubygems.org'

gem 'json', '~> 1.8.0'
gem 'rails', '3.2.13'
gem 'haml'
gem 'mysql2'

# Needs to be outside of assets group because it’s needed in production
# Use a patched version with an updated r.js file
gem 'requirejs-rails', '0.9.1', path: 'vendor/gems/requirejs-rails-0.9.1'

gem 'memcache-client'
gem 'rubyzip', require: 'zip/zip'
gem 'exception_notification'
gem 'http_accept_language'

group :assets do
  gem 'coffee-rails'
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'haml_coffee_assets'
  gem 'therubyracer', '0.11.4', platform: :ruby
  gem 'libv8', '3.11.8.13', platform: :ruby
  gem 'uglifier'
end

group :development do
  gem 'thin'
  gem 'quiet_assets'
  gem 'debugger'
  gem 'guard'
  gem 'guard-coffeescript'
  gem 'guard-livereload'
  gem 'rb-fsevent'
  gem 'capistrano'
end

#group :test do
  #gem 'jasmine'
  #gem 'guard-jasmine'
  #gem 'jasminerice'
  #gem 'jasmine-stories'
  #gem 'capybara'
  #gem 'capybara-firebug'
  #gem 'capybara-webkit'
  #gem 'cucumber'
  #gem 'cucumber-rails'
  #gem 'cucumber_factory'
  gem 'rspec-rails'
  #gem 'shoulda'
  #gem 'spork'
  #gem 'webmock'
#end
