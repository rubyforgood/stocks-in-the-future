# frozen_string_literal: true

require "application_system_test_case"

# The chrome and the content share one gutter, and it is equal on both sides.
#
# Reported first as the hamburger sitting further in than the cards: the content edge was 16px
# (main's px-4) while the header was px-6, so the trigger sat at 24px.
#
# Then reported twice more, because of how that was fixed. A 44px target centring a 24px glyph puts
# the glyph 10px inside its own box, so the glyph was pulled onto the gutter with a negative margin -
# and **whatever paints comes with it**. A filled button hung 6px past the edge; making it borderless
# left a hover fill doing the same thing on hover; a 40px state layer inside the target still sat at
# 8px against content at 16px.
#
# **The box that paints is the box that aligns.** No negative margins: the trigger's own 44px box is
# flush with the gutter, and the glyph sits 10px inside it, which is inherent to centring an icon in
# a touch target and is what GitHub Primer and Polaris ship. The radius is `rounded-lg` - design.md's
# token is "controls rounded-lg", and rounded-full was an aesthetic override of an explicit spec.
class ChromeGutterTest < ApplicationSystemTestCase
  CONTROL_RADIUS = "8px"

  MEASURE = <<~JS
    (function () {
      const vw = document.documentElement.clientWidth;
      const out = {};
      const trigger = document.querySelector("[data-testid='open-navigation']");
      if (trigger && trigger.getClientRects().length) {
        const b = trigger.getBoundingClientRect();
        const cs = getComputedStyle(trigger);
        out.triggerLeft = Math.round(b.left);
        out.triggerTarget = Math.round(Math.min(b.width, b.height));
        out.triggerRadius = cs.borderTopLeftRadius;
        out.triggerMargin = cs.marginLeft;
        const glyph = trigger.querySelector("svg");
        if (glyph) out.glyphLeft = Math.round(glyph.getBoundingClientRect().left);
      }
      const summary = document.querySelector("[data-testid='account-menu'] > summary");
      if (summary) {
        const s = getComputedStyle(summary);
        out.accountRight = Math.round(vw - summary.getBoundingClientRect().right);
        out.accountRadius = s.borderTopLeftRadius;
        out.accountMargin = s.marginRight;
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

  def measurements
    # Capybara waits; evaluate_script does not. Measuring straight after a visit raced - one run in
    # nine read the page before the account menu existed, so its inset came back nil.
    assert_selector "[data-testid='account-menu']", visible: :all

    page.evaluate_script(MEASURE)
  end

  def assert_chrome_on_gutter(label, gutter)
    m = measurements

    assert_equal gutter, m["cardLeft"], "#{label}: card left"
    assert_equal gutter, m["cardRight"],
                 "#{label}: card right - the margins must be equal on both sides"
    assert_equal gutter, m["h1Left"], "#{label}: the page title" if m["h1Left"]

    assert_equal gutter, m["accountRight"],
                 "#{label}: the account control's box is not on the gutter"
    assert_equal CONTROL_RADIUS, m["accountRadius"],
                 "#{label}: the account control is not on the rounded-lg control token"
    assert_equal "0px", m["accountMargin"],
                 "#{label}: a negative margin drags the paint off the gutter"

    return unless m["triggerLeft"]

    assert_equal gutter, m["triggerLeft"],
                 "#{label}: the navigation trigger's box is not on the gutter. The box is what " \
                 "paints, so the box is what aligns - do not pull it out to chase the glyph"
    assert_equal CONTROL_RADIUS, m["triggerRadius"],
                 "#{label}: the trigger is not on the rounded-lg control token"
    assert_equal "0px", m["triggerMargin"],
                 "#{label}: the trigger carries a negative margin, which is what put its fill " \
                 "past the content edge three times"
    assert_operator m["triggerTarget"], :>=, 44,
                    "#{label}: the touch target shrank below 44px"
    assert_operator m["glyphLeft"], :>, gutter,
                    "#{label}: the glyph should sit inside its own box, not on the gutter"
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
      assert_chrome_on_gutter("app @375", 16)
    end
  end

  test "admin shares the same gutter on a phone" do
    sign_in(create(:admin))

    in_phone_viewport do
      visit admin_users_path
      assert_chrome_on_gutter("admin @375", 16)
    end
  end

  test "the chrome's trailing edge matches the content at lg" do
    sign_in(student_with_data)

    in_chromebook_viewport do
      visit stocks_path
      m = measurements

      # The sidebar owns the left at lg, so only the trailing edge is comparable.
      assert_equal 24, m["cardRight"], "the content gutter at lg"
      assert_equal 24, m["accountRight"],
                   "the account control does not share the content's trailing edge at lg"
    end
  end

  # Both halves of the product use the same treatment.
  test "both navigation triggers are the same control" do
    sign_in(student_with_data)
    app = nil
    in_phone_viewport do
      visit stocks_path
      app = measurements
    end

    sign_in(create(:admin))
    admin = nil
    in_phone_viewport do
      visit admin_users_path
      admin = measurements
    end

    %w[triggerLeft triggerTarget triggerRadius triggerMargin].each do |property|
      assert_equal app[property], admin[property],
                   "the app and admin navigation triggers differ on #{property}; they are one " \
                   "control in one product"
    end
  end
end
