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
  LG_MINIMUM = [1024, 768].freeze
  DEFAULT_SIZE = [1400, 1400].freeze
  REFLOW_WIDTH = 320

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

  # 1024x768: Tailwind's `lg` minimum, and a real width - an iPad in landscape, a small laptop. It is
  # where the widest tables still overflow now that the primary cell wraps and every secondary column
  # collapses below `lg`: measured, admin/users runs 202px past its container here, admin/stocks 298px
  # and admin/teachers 251px, while all of them fit a Chromebook. That makes it the only width at which
  # the pinned actions cell does anything, so it is the width its test has to run at.
  def in_lg_minimum_viewport
    resize_window_to(*LG_MINIMUM)
    wait_until { desktop_viewport? }
    yield
  ensure
    resize_window_to(*DEFAULT_SIZE)
    wait_until { desktop_viewport? }
  end

  # 320px, the WCAG 1.4.10 Reflow width, through CDP rather than `resize_to`.
  #
  # A Chrome *window* will not go below about 500px, so `resize_to(320, ...)` silently gives you ~500 and
  # a test that believes it checked 320px. `Emulation.setDeviceMetricsOverride` sets the viewport
  # directly; measured, it yields a 305px client width here, the remainder being the scrollbar.
  def in_reflow_viewport
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: REFLOW_WIDTH, height: 640, deviceScaleFactor: 1, mobile: false
    )
    yield
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  # 200% text, for WCAG 1.4.4.
  #
  # Doubling the root font size is the standard automated proxy: Tailwind sizes type *and* spacing in
  # rem, so this scales the same things browser zoom does. It is not identical to zoom - it leaves px
  # values alone - which makes it the harsher test for exactly the failure mode that matters here, a box
  # with a fixed height holding text that has grown.
  #
  # It has to be re-applied after every `visit`, because navigation replaces the documentElement.
  def with_text_at_200_percent
    apply_200_percent_text
    yield
  ensure
    page.execute_script("document.documentElement.style.fontSize = ''")
  end

  def apply_200_percent_text
    page.execute_script("document.documentElement.style.fontSize = '32px'")
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

  # Switching users needs the UI, not `sign_out`.
  #
  # Devise's `sign_out` is `Warden::Test::Helpers#logout`, which *queues* the logout for the next
  # request the Warden middleware handles. In a request test that is the next request you make; in a
  # system test it is whichever request arrives first, and a queued block can also fire later and sign
  # the previous user back in. Measured on `teacher_creates_student_test`: signing out, signing in as
  # the student and then reading the account menu found the **teacher** there in 4 of 10 full runs.
  # Clearing the browser cookies and calling `Warden.test_reset!` did not fix it; going through the
  # account menu did, 10 runs out of 10.
  #
  # The old assertion could not see any of this, because it checked for the home page's h1 - and the
  # teacher's home page has the same h1. The test passed while signed in as the wrong user.
  #
  # `sign_out` is left alone and is fine where a test only signs out: nothing after it depends on the
  # session having ended by a particular moment.
  # The other half of the same problem. `sign_out_through_the_ui` fixed the *logout*; a test that then has
  # to be a different user still had `sign_in`'s queued `Warden.on_next_request` block behind it, and that
  # block can fire late and set the previous user back. Measured as
  # `TeacherCreatesStudentTest#test_teacher_can_reset_student_password` failing with **the teacher's** name
  # in the account menu after signing out and signing in as the student - which is the failure this file's
  # note already described, surviving the mitigation because the mitigation only covered one direction.
  #
  # A test that switches users signs **both** of them in through the form, so nothing is ever queued. It
  # was written out locally in `flash_dismiss_test` and `flash_width_test` before this; two copies of a
  # helper is how they drift, so those call it now.
  # **It waits.** `click_on` does not block, so without the last line the next `visit` races the sign-in
  # POST and lands signed out - which is how the first version of this broke three tests: a classroom page
  # with no rows, and twice "no flash on screen to measure". The two local copies disagreed about exactly
  # this, one waiting on the flash text and one not, and merging them lost the wait.
  #
  # The account menu rather than the flash: it names the signed-in user, renders on every signed-in page,
  # and does not auto-dismiss after 6 seconds the way the flash does.
  def sign_in_through_the_ui(username, password: "Passw0rd")
    visit new_user_session_path
    fill_in "Username", with: username
    fill_in "Password", with: password
    click_on "Sign in"
    assert_selector "[data-testid='account-menu']"
  end

  def sign_out_through_the_ui
    find("[data-testid='account-menu'] summary").click
    click_on "Sign out"
    assert_field "Username"
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
