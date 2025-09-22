# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.start "rails" do
    add_filter "/test/"
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "helpers/policy_test_helper"
require_relative "support/csv_test_helper"
require "rails/test_help"
require "webmock/minitest"
require "mocha/minitest"

# TODO: Remove this workaround once Devise is updated to support Rails 8
# Rails 8 introduced deferred route drawing which breaks Devise's sign_in helper
# This forces routes to load before tests run, ensuring Devise mappings are available
# See: https://github.com/heartcombo/devise/issues/5705
Rails.application.routes_reloader.execute_unless_loaded if Rails.application.respond_to?(:routes_reloader)

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include CsvTestHelper

    # Use PARALLEL_WORKERS=1 if you want to change the number of workers
    # For instance, PARALLEL_WORKERS=1 bin/dc rails test
    parallelize(workers: ENV["PARALLEL_WORKERS"]&.to_i || :number_of_processors)

    # Add more helper methods to be used by all tests here...
    def t(...)
      I18n.t(...)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
