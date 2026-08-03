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

  # design.md's two widths. Everything here runs at 1400x1400 by default, which is why nothing
  # had ever exercised the mobile drawer: it only exists below lg (1024px). Resizing per test
  # rather than adding a second driver keeps one browser for the suite.
  PHONE = [375, 812].freeze
  DEFAULT_SIZE = [1400, 1400].freeze

  # Restores the default size afterwards. Capybara reuses the browser between tests, so a test
  # that resized and did not restore would silently hand a 375px window to whatever ran next.
  #
  # Both directions wait for the media query the CSS actually keys on. resize_to returns before
  # the browser has finished applying it, and a test that carried on regardless saw a desktop
  # layout at phone width - which showed up as a single failure in one full-suite run and passed
  # on every rerun. Waiting on the query makes it deterministic rather than usually fine.
  def in_phone_viewport
    resize_window_to(*PHONE)
    wait_until { !desktop_viewport? }
    yield
  ensure
    resize_window_to(*DEFAULT_SIZE)
    wait_until { desktop_viewport? }
  end

  private

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  # 64rem is Tailwind's lg, the width at which the sidebar stops being a drawer.
  def desktop_viewport?
    page.evaluate_script('window.matchMedia("(min-width: 64rem)").matches')
  end

  # An off-canvas panel is moved by a transform, and Capybara's visible? reads display,
  # visibility and opacity - not transforms - so a closed drawer still counts as visible. Its
  # position is what actually says open or closed.
  def offscreen_to_the_left?(selector)
    page.evaluate_script(
      "document.querySelector(#{selector.to_json}).getBoundingClientRect().right <= 0"
    )
  end

  # The drawer slides over 300ms, so a bare assertion right after a click reads a mid-transition
  # position and fails on a drawer that is opening correctly. Capybara's own matchers retry; a
  # raw evaluate_script does not, so these wait first and then assert.
  #
  # The wait and the assertion are deliberately separate. An earlier version returned early on
  # success, which recorded no assertion at all - minitest reported "missing assertions", and a
  # test that asserts nothing can pass without verifying anything.
  def assert_offscreen(selector, message)
    wait_until { offscreen_to_the_left?(selector) }

    assert offscreen_to_the_left?(selector), message
  end

  def assert_onscreen(selector, message)
    wait_until { !offscreen_to_the_left?(selector) }

    assert_not offscreen_to_the_left?(selector), message
  end

  def wait_until(timeout: Capybara.default_max_wait_time)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    until yield
      break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.05
    end
  end

  def auto_accept_confirmations
    page.execute_script("window.confirm = () => true")
  end
end
