# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.4"

gem "rails", "~> 8.0.2"

gem "administrate", "1.0.0.beta3"
gem "bootsnap", require: false
gem "csv"
gem "daemons"
gem "delayed_job_active_record"
gem "devise", "~> 4.9"
gem "faker", "~> 3.5.2"
gem "font-awesome-rails"
gem "importmap-rails"
gem "jbuilder"
gem "pg", "~> 1.6"
gem "propshaft"
gem "puma", ">= 5.0"
gem "pundit", "~> 2.5"
gem "shadcn-ui", "~> 0.0.15"
gem "stimulus-rails"
gem "strong_migrations", "~> 2.5"
gem "tailwindcss-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "whenever", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "pry", "~> 0.15.2"
  gem "rubocop"
  gem "rubocop-rails"
end

group :development do
  gem "bundler-audit"
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
