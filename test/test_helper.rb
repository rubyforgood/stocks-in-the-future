require "simplecov"

SimpleCov.start "rails" do
  add_filter "/test/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "mocha/minitest"

# TODO: Remove this workaround once Devise is updated to support Rails 8
# Rails 8 introduced deferred route drawing which breaks Devise's sign_in helper
# This forces routes to load before tests run, ensuring Devise mappings are available
# See: https://github.com/heartcombo/devise/issues/5705
if Rails.application.respond_to?(:routes_reloader)
  Rails.application.routes_reloader.execute_unless_loaded
end

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
    def t(...)
      I18n.t(...)
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
