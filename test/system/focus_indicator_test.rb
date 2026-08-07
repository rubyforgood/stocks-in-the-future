# frozen_string_literal: true

require "application_system_test_case"

# Every focusable control shows the app's own focus indicator, not the browser's.
#
# The convention, from counting it: `focus-visible:outline-2 focus-visible:outline-offset-2` with a named
# colour - 28 uses of the first two, 25 of `outline-sitf-primary`. Outline, not ring. Three checkboxes on
# `classrooms#edit` were the exception: they carried `focus-visible:ring-sitf-primary`, which sets a ring
# *colour* and no ring *width*, so nothing painted and they fell back to Chrome's `1px auto rgb(16,16,16)`.
class FocusIndicatorTest < ApplicationSystemTestCase
  # Chrome's default focus ring is `auto` style. Anything the app draws is `solid`, so the style alone
  # separates "styled by us" from "left to the browser".
  READ = <<~JS
    (function () {
      const el = document.activeElement;
      if (!el || el === document.body) return null;
      const cs = getComputedStyle(el);
      return { tag: el.tagName.toLowerCase(),
               type: el.getAttribute("type"),
               text: (el.value || el.textContent || "").trim().slice(0, 24),
               focusVisible: el.matches(":focus-visible"),
               style: cs.outlineStyle,
               width: cs.outlineWidth,
               colour: cs.outlineColor,
               offset: cs.outlineOffset };
    })()
  JS

  # The button base transitions `outline-color`, so a computed read taken in the same instant as the focus
  # returns the *interpolated start* value, which is `currentColor` - white on a filled primary. Measured
  # that way, this app's main action looks like it has an invisible focus ring on a white page. It does
  # not. Anything reading a transitioned property has to let the transition finish first.
  SETTLE = 0.35

  def focus_next
    page.driver.browser.action.send_keys(:tab).perform
    sleep SETTLE
    page.evaluate_script(READ)
  end

  def assert_app_focus_ring(control)
    assert control["focusVisible"], "#{control['text']} did not take :focus-visible"
    assert_equal "solid", control["style"],
                 "#{control['text']} shows the browser's default ring (#{control['width']} " \
                 "#{control['style']} #{control['colour']}), not the app's"
    assert_equal "2px", control["width"], "#{control['text']} rings at #{control['width']}, not 2px"
    assert_not_equal "rgba(0, 0, 0, 0)", control["colour"], "#{control['text']} has a transparent ring"
  end

  test "every focusable control on the classroom form draws the app's ring" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit edit_classroom_path(classroom)

    seen = 0
    40.times do
      control = focus_next
      next if control.nil?
      # Only what the page itself owns; the layout's nav is covered by its own tests.
      next unless %w[input button a select textarea].include?(control["tag"])
      next if control["type"] == "hidden"

      assert_app_focus_ring(control)
      seen += 1
      break if seen >= 6
    end

    assert_operator seen, :>=, 3, "tabbed through the form and found fewer than three controls"
  end

  # The checkbox specifically, because it is the one that was wrong and the failure was silent: a ring
  # colour with no ring width paints nothing at all.
  test "a checkbox draws the app's ring, not the browser's" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit edit_classroom_path(classroom)

    box = page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector("input[type=checkbox]");
        el.focus();
        return el.className;
      })()
    JS

    assert_includes box, "focus-visible:outline-2"
    assert_includes box, "focus-visible:outline-sitf-primary"
    assert_not_includes box, "ring-sitf-primary",
                        "a ring colour with no ring width paints nothing; this app draws focus with outline"
  end

  # No control shows a ring at rest. This is what makes a mock that paints one misleading - a preview of
  # the destructive-button proposal did exactly that, and it is why `focus-visible` state has to be
  # described in words rather than drawn.
  test "no control carries a focus ring at rest" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit edit_classroom_path(classroom)

    ringed = page.evaluate_script(<<~JS)
      (function () {
        const out = [];
        document.querySelectorAll("main a, main button, main input, main select").forEach(function (el) {
          if (el.getClientRects().length === 0) return;
          if (el === document.activeElement) return;
          const cs = getComputedStyle(el);
          if (cs.outlineStyle !== "none" && parseFloat(cs.outlineWidth) > 0) {
            out.push((el.value || el.textContent || el.type || "").trim().slice(0, 20) +
                     " " + cs.outlineWidth + " " + cs.outlineStyle);
          }
        });
        return out;
      })()
    JS

    assert_empty ringed, "these carry a ring while unfocused: #{ringed.join(', ')}"
  end
end
