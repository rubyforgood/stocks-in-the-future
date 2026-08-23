# frozen_string_literal: true

require "application_system_test_case"

# `prefers-reduced-motion: reduce`, which is a real setting on every major OS.
#
# Before this the app honoured it in one place - the flash fade - while both nav drawers slid 256px on a
# 300ms transform. The rule restricts which properties may transition rather than zeroing every duration,
# because the query is about motion and a colour fade is not motion in the sense that causes trouble.
#
# Emulated through CDP rather than assumed: `Emulation.setEmulatedMedia` is the only way to put this
# browser in that state, and without it the media query is dead code that no test can see.
class ReducedMotionTest < ApplicationSystemTestCase
  def with_reduced_motion
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [{ name: "prefers-reduced-motion", value: "reduce" }]
    )
    yield
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  def transition_of(selector)
    page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector(#{selector.to_json});
        const s = getComputedStyle(el);
        return { property: s.transitionProperty, duration: s.transitionDuration };
      })()
    JS
  end

  test "the drawer stops sliding, and a colour fade is left alone" do
    sign_in create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    in_phone_viewport do
      visit root_path

      # The baseline, asserted rather than assumed: without this the test could pass against a drawer that
      # never transitioned in the first place.
      ordinary = transition_of("#main-navigation")

      assert_includes ordinary["property"], "transform"
      assert_equal "0.3s", ordinary["duration"]

      with_reduced_motion do
        visit root_path
        reduced = transition_of("#main-navigation")

        assert_not_includes reduced["property"], "transform",
                            "the drawer still animates its transform for somebody who asked for less motion"

        # And the fade survives, which is the point of restricting the property list rather than the
        # duration: a button that snaps between colours is not what the setting asks for.
        assert_includes transition_of(".tw-btn-primary, .tw-link")["property"], "color"
      end
    end
  end

  test "an animation collapses to nothing" do
    sign_in create(:admin)

    with_reduced_motion do
      visit admin_root_path

      duration = page.evaluate_script(<<~JS)
        (function () {
          const el = document.createElement("div");
          el.style.animation = "spin 2s linear infinite";
          document.body.appendChild(el);
          const s = getComputedStyle(el);
          const out = { duration: s.animationDuration, count: s.animationIterationCount };
          el.remove();
          return out;
        })()
      JS

      # 0.01ms, which the browser reports in scientific notation
      assert_equal "1e-05s", duration["duration"]
      assert_equal "1", duration["count"]
    end
  end
end
