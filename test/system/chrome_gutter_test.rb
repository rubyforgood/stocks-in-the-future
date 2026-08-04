# frozen_string_literal: true

require "application_system_test_case"

# The chrome and the content share one gutter, and it is equal on both sides.
#
# Reported as the hamburger sitting further in than the cards. Measured below lg, before: the
# content edge was 16px (main's px-4) while the header was px-6, so the trigger's box sat at 24px -
# and because a 44px hit area centres a 24px icon, the *glyph* landed at 34px. Three different
# numbers for one edge.
#
# The insets are optical: -ml-2.5 on the menu trigger and -mr-2 on the account trigger pull their
# hit areas out so the glyph, not the box, lands on the content edge. That is only right for a
# borderless control, which is why the app's trigger is no longer a filled teal button - a visible
# fill hanging 6px from the viewport edge is worse than one 8px too far in. It also now matches
# admin's, which was already a ghost.
class ChromeGutterTest < ApplicationSystemTestCase
  MEASURE = <<~JS
    (function () {
      const vw = document.documentElement.clientWidth;
      const out = {};
      const trigger = document.querySelector("[data-testid='open-navigation']");
      const glyph = trigger ? trigger.querySelector("svg") : null;
      if (glyph && glyph.getClientRects().length) {
        out.triggerGlyphLeft = Math.round(glyph.getBoundingClientRect().left);
      }
      const summary = document.querySelector("[data-testid='account-menu'] > summary");
      if (summary) {
        const kids = Array.from(summary.children).filter(function (e) {
          return e.getClientRects().length && !e.classList.contains("sr-only");
        });
        const last = kids.pop();
        if (last) out.accountGlyphRight = Math.round(vw - last.getBoundingClientRect().right);
      }
      const card = document.querySelector("main .tw-card, main .table-wrapper, main section");
      if (card) {
        const b = card.getBoundingClientRect();
        out.cardLeft = Math.round(b.left);
        out.cardRight = Math.round(vw - b.right);
      }
      const h1 = document.querySelector("main h1");
      if (h1) out.h1Left = Math.round(h1.getBoundingClientRect().left);
      return out;
    })()
  JS

  # Below lg there is no sidebar, so every edge is the gutter itself.
  def assert_one_gutter(label, expected)
    m = page.evaluate_script(MEASURE)

    assert_equal expected, m["cardLeft"], "#{label}: card left"
    assert_equal expected, m["cardRight"],
                 "#{label}: card right - the margins must be equal on both sides"
    assert_equal expected, m["h1Left"], "#{label}: the page title" if m["h1Left"]
    if m["triggerGlyphLeft"]
      assert_equal expected, m["triggerGlyphLeft"],
                   "#{label}: the navigation trigger's glyph is not on the content edge"
    end
    return unless m["accountGlyphRight"]

    assert_equal expected, m["accountGlyphRight"],
                 "#{label}: the account menu's glyph is not on the content edge"
  end

  def student_with_data
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    student
  end

  test "the app shares one 16px gutter on a phone" do
    sign_in(student_with_data)

    in_phone_viewport do
      visit stocks_path
      assert_one_gutter("app @375", 16)
    end
  end

  test "admin shares the same gutter on a phone" do
    sign_in(create(:admin))

    in_phone_viewport do
      visit admin_users_path
      assert_one_gutter("admin @375", 16)
    end
  end

  test "the chrome's trailing edge matches the content at lg" do
    sign_in(student_with_data)

    in_chromebook_viewport do
      visit stocks_path
      m = page.evaluate_script(MEASURE)

      # The sidebar owns the left at lg, so only the trailing edge is comparable.
      assert_equal 24, m["cardRight"], "the content gutter at lg"
      assert_equal 24, m["accountGlyphRight"],
                   "the account menu's glyph does not share the content's trailing edge at lg"
    end
  end

  # Both halves of the product use the same trigger treatment, and the visible surface keeps clear
  # of the viewport edge.
  #
  # The optical inset that puts the glyph on the gutter pulls a 44px hit area to 6px from the edge.
  # That is fine while nothing paints there - but the trigger has a hover background, so the fill
  # rendered 6px from the edge with 6px to the left of the glyph against 16px on the right. A
  # negative margin is only safe on a control that paints *nothing*, at rest or on hover.
  #
  # Resolved with Material 3's state layer: the 44px target stays, and the visible surface is a
  # 40px circle inside it, so it stops 8px short of the edge - the same inset the account menu's
  # pill has on the right - while the glyph still lands on the 16px gutter.
  #
  # Asserted as geometry and as a class contract, because Tailwind emits hover: inside
  # @media (hover:hover) and the headless Chromium here reports (hover: none): the rendered hover
  # fill cannot be observed at all, which is why the first version of this test - checking the
  # button's resting backgroundColor - could not have caught the bug it was written for.
  test "the navigation trigger's visible surface clears the viewport edge" do
    sign_in(student_with_data)

    in_phone_viewport do
      visit stocks_path
      assert_trigger_surface("app")
    end
  end

  test "admin's navigation trigger has the same surface" do
    sign_in(create(:admin))

    in_phone_viewport do
      visit admin_users_path
      assert_trigger_surface("admin")
    end
  end

  def assert_trigger_surface(label)
    # Capybara waits; evaluate_script does not. Measuring straight after a visit raced - one run in
    # nine read the page before the account menu existed, so its inset came back nil.
    assert_selector "[data-testid='open-navigation']", visible: :all
    assert_selector "[data-testid='account-menu']", visible: :all

    m = page.evaluate_script(<<~JS)
      (function () {
        const vw = document.documentElement.clientWidth;
        const btn = document.querySelector("[data-testid='open-navigation']");
        const surface = btn.querySelector("span:not(.sr-only)");
        const glyph = btn.querySelector("svg");
        const summary = document.querySelector("[data-testid='account-menu'] > summary");
        const b = btn.getBoundingClientRect();
        const s = surface.getBoundingClientRect();
        return {
          target: Math.round(Math.min(b.width, b.height)),
          surfaceLeft: Math.round(s.left),
          surfaceSize: Math.round(s.width),
          glyphLeft: Math.round(glyph.getBoundingClientRect().left),
          buttonPaints: getComputedStyle(btn).backgroundColor !== "rgba(0, 0, 0, 0)",
          surfaceHoverClass: /group-hover:bg-/.test(surface.className),
          accountPillRight: summary
            ? Math.round(vw - summary.getBoundingClientRect().right)
            : null
        };
      })()
    JS

    assert_operator m["target"], :>=, 44, "#{label}: the touch target shrank below 44px"
    assert_equal 16, m["glyphLeft"], "#{label}: the glyph is off the content gutter"
    assert_operator m["surfaceLeft"], :>=, 8,
                    "#{label}: the visible surface is #{m['surfaceLeft']}px from the edge - it " \
                    "hangs off. Put the optical inset on the hit area, not on the thing that paints"
    assert_equal m["accountPillRight"], m["surfaceLeft"],
                 "#{label}: the leading and trailing controls sit at different insets"
    assert_not m["buttonPaints"],
               "#{label}: the pulled-out button paints its own background, which is what hangs " \
               "off the edge; the state layer inside it should paint instead"
    assert m["surfaceHoverClass"],
           "#{label}: the hover fill is not on the inset surface. It cannot be measured in this " \
           "browser - @media (hover:hover) never matches - so its placement is asserted as a class"
  end
end
