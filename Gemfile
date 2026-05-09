# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.4"

gem "rails", "~> 8.1.2", ">= 8.1.2.1"

gem "bootsnap", require: false
gem "csv"
gem "daemons"
gem "devise", "~> 5.0"
gem "faker", "~> 3.8.0"
gem "font-awesome-rails"
gem "image_processing", "~> 1.14"
gem "importmap-rails"
gem "jbuilder"
gem "lucide-rails"
gem "pg", "~> 1.6"
gem "propshaft"
gem "puma", ">= 5.0"
gem "pundit", "~> 2.5"
gem "shadcn-ui", "~> 0.0.15"
gem "solid_queue", "~> 1.4"
gem "stimulus-rails"
gem "strong_migrations", "~> 2.7"
gem "tailwindcss-rails"
gem "turbo-rails"

gem "discard", "~> 1.4"
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows]
  gem "erb_lint", require: false
  gem "pry", "~> 0.16.0"
  gem "pry-byebug"
  gem "rubocop"
  gem "rubocop-rails"
end

group :development do
  gem "capistrano", "~> 3.19", require: false
  gem "capistrano-rbenv", "~> 2.2", require: false
  gem "capistrano-bundler", "~> 2.1", require: false
  gem "capistrano-rails", "~> 1.6", require: false
  gem "ed25519", "~> 1.3", require: false
  gem "bcrypt_pbkdf", "~> 1.0", require: false
  gem "i18n-tasks"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "mocha"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webmock"
end
