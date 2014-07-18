# -*- coding: utf-8 -*-
source 'https://rubygems.org'

gem 'rails', '~> 3.2.19'
gem 'haml'
gem 'mysql2'

# Needs to be outside of assets group because it’s needed in production
# Use a patched version with an updated r.js file
gem 'requirejs-rails', '0.9.1', path: 'vendor/gems/requirejs-rails-0.9.1'
gem 'memcache-client'
gem 'rubyzip'
gem 'exception_notification'
gem 'http_accept_language'
gem 'diffy'

group :assets do
  gem 'coffee-rails'
  gem 'sass-rails'
  gem 'compass-rails'
  # Lock old version because of several bugs
  # e.g. https://github.com/netzpirat/haml_coffee_assets/issues/121
  gem 'haml_coffee_assets', '1.13.2'
  # Explicitly lock tilt to avoid clashes with Rails
  # see https://github.com/netzpirat/haml_coffee_assets/issues/118
  gem 'tilt', '~> 1.3.3'
  gem 'therubyracer', '~> 0.12.0', platform: :ruby
  gem 'libv8', '~> 3.16.14.3', platform: :ruby
  gem 'uglifier'
end

group :development do
  gem 'pry'
  gem 'better_errors'
  gem 'thin'
  gem 'quiet_assets'
  #gem 'ruby-debug'
  #gem 'ruby-debug-ide'
  gem 'byebug'
  gem 'guard'
  gem 'guard-coffeescript'
  gem 'guard-livereload'
  gem 'rb-fsevent'
  gem 'capistrano', '~> 2.15.5'
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
  gem 'guard-rspec', require: false
  #gem 'shoulda'
  #gem 'spork'
  #gem 'webmock'
#end
