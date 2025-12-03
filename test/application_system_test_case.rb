# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers

  # You can run the system test in an actual browser for visually validate the system test.
  # eg. TEST_DRIVER=chrome rails test test/system/student_trading_flow_test.rb
  # note: it does NOT work with Docker (needs standalone chrome + VNC)
  driven_by :selenium,
            using: ENV.fetch("TEST_DRIVER", "headless_chrome").to_sym,
            screen_size: [1400, 1400] do |driver_option|
    driver_option.add_argument("--no-sandbox")
    driver_option.add_argument("--disable-dev-shm-usage")
  end

  private

  def auto_accept_confirmations
    page.execute_script("window.confirm = () => true")
  end
end
