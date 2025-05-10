source "https://rubygems.org"

ruby "3.2.3"

gem "rails", "~> 7.2.2"

gem "administrate", "~> 0.20.1"
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "daemons"
gem "delayed_job_active_record"
gem "devise", "~> 4.9"
gem "jbuilder"
gem "jsbundling-rails"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "shadcn-ui", "~> 0.0.15"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]

  # a linting tool, to encourage/enforce a consistent code style
  gem "standard-rails"
  gem "standardrb"
end

group :development do
  gem "bundler-audit"
  gem "i18n-tasks"
  gem "pry", "~> 0.15.2"
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

gem "pundit", "~> 2.5"
