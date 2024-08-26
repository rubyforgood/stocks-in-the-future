source "https://rubygems.org"

ruby "3.2.3"

gem "rails", "~> 7.2.1"

gem "administrate", "~> 0.20.1"
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "daemons"
gem "delayed_job_active_record"
gem "devise", "~> 4.9"
gem "jbuilder"
gem "jsbundling-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "shadcn-ui", "~> 0.0.12"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]

  # a linting tool, to encourage/enforce a consistent code style
  gem "standardrb"
  gem "standard-rails"
end

group :development do
  gem "bundler-audit"
  gem "pry", "~> 0.14.2"
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock"
end

gem "pundit", "~> 2.3"
