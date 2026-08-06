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
  CHROMEBOOK = [1366, 768].freeze
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

  # The primary target: students on school Chromebooks. The default 1400x1400 window is taller
  # than any real screen, so anything that only overflows on a short viewport - a long sidebar,
  # for one - is invisible without this.
  def in_chromebook_viewport
    resize_window_to(*CHROMEBOOK)
    yield
  ensure
    resize_window_to(*DEFAULT_SIZE)
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

  # Waits for the panel to be *fully* in, not merely peeking. offscreen_to_the_left? goes false
  # the instant the panel starts entering, so a test that clicked straight afterwards was
  # clicking a moving target - which failed about one run in three with "drawer should be off
  # canvas once closed", because the close click had landed mid-transition.
  def assert_onscreen(selector, message)
    wait_until { fully_onscreen?(selector) }

    assert fully_onscreen?(selector), message
  end

  def fully_onscreen?(selector)
    page.evaluate_script(
      "document.querySelector(#{selector.to_json}).getBoundingClientRect().left >= -1"
    )
  end

  def wait_until(timeout: Capybara.default_max_wait_time)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    until yield
      break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.05
    end
  end

  # The app's own confirmation dialog, not the browser's.
  #
  # `accept_confirm` waits for a *native* JS dialog, so every one of its 20 call sites raised
  # ModalNotFound the moment `Turbo.config.forms.confirm` started rendering HTML instead. That was the
  # predicted cost of a styled confirm and the reason it was written down before being built: the risk is
  # never the dialog, it is the call sites that were driving the old one.
  #
  # Same shape as `accept_confirm` - pass the block that triggers it - so the diff at each site is one
  # word.
  def accept_confirmation(&block)
    block.call
    find("#confirm-dialog[open] [data-confirm-dialog-target='accept']").click
    assert_no_selector "#confirm-dialog[open]"
  end

  def dismiss_confirmation(&block)
    block.call
    within("#confirm-dialog[open]") { click_on "Cancel" }
    assert_no_selector "#confirm-dialog[open]"
  end

  # Was `window.confirm = () => true`. It no longer intercepts anything - the confirmation is HTML now -
  # and it has no callers left, so it is gone rather than kept as a no-op that reads like it still works.
end
