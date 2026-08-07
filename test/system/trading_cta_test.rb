# frozen_string_literal: true

require "application_system_test_case"

# The trading floor's call to action has to be on screen.
#
# It was not, on a phone. Buy and Sell sat in a trailing column at left=370 inside a wrapper
# 326px wide, so the only call to action in the student-facing product was past the right edge of
# a horizontal scroll at 375px - the width most of these students are on. Nothing failed: the
# buttons were in the DOM, Capybara could click them, and every assertion about them passed,
# because a test that asks "is it present" cannot see "is it reachable".
class TradingCtaTest < ApplicationSystemTestCase
  def trading_student
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    student
  end

  # The visible copy: below lg the buttons render inside the primary cell, at lg in the trailing
  # actions column, so the DOM holds both and only one of them has a box.
  def visible_cta
    page.evaluate_script(<<~JS)
      (function () {
        const all = Array.from(document.querySelectorAll("[data-testid='buy-stock-button']"));
        const btn = all.find(function (e) { return e.getClientRects().length > 0; });
        if (!btn) return null;
        const wrap = btn.closest(".table-wrapper");
        const b = btn.getBoundingClientRect();
        const w = wrap.getBoundingClientRect();
        return {
          within: b.left >= w.left - 1 && b.right <= w.right + 1,
          scrollable: wrap.scrollWidth > wrap.clientWidth + 1,
          width: Math.round(b.width),
          height: Math.round(b.height)
        };
      })()
    JS
  end

  test "the buy control is on screen on a phone without horizontal scrolling" do
    sign_in(trading_student)

    in_phone_viewport do
      visit stocks_path
      cta = visible_cta

      assert_not_nil cta, "no visible Buy control at 375px"
      assert cta["within"], "Buy is outside the visible width of its scroll container at 375px"
      assert_not cta["scrollable"],
                 "the stocks table still scrolls horizontally at 375px, which is how the CTA " \
                 "went off screen in the first place"
      assert_operator cta["height"], :>=, 40
    end
  end

  test "the buy control is on screen on a Chromebook" do
    sign_in(trading_student)

    in_chromebook_viewport do
      visit stocks_path
      cta = visible_cta

      assert_not_nil cta, "no visible Buy control at 1366px"
      assert cta["within"], "Buy is outside the visible width of its scroll container at 1366px"
    end
  end

  test "exactly one buy control is visible per stock at each width" do
    sign_in(trading_student)

    [method(:in_phone_viewport), method(:in_chromebook_viewport)].each do |viewport|
      viewport.call do
        visit stocks_path

        assert_selector "[data-testid='buy-stock-button']", count: 1,
                                                            visible: true
      end
    end
  end

  # The mismatch this fixed. The header asked current_user.student? while the row asked
  # policy(stock).show_holdings?, which also requires a persisted portfolio - so a student without
  # one got four header cells over two body cells. Reachable in real data: the seeds build students
  # with User.find_or_initialize_by and set type afterwards, which leaves a User instance, so
  # Student's after_create :ensure_portfolio never runs.
  test "a student with no portfolio gets a table whose columns still line up" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom: classroom)
    student.reload
    student.portfolio.destroy!
    student.reload
    create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(student)

    visit stocks_path

    # This raised before: the earnings card was gated on `show_holdings? || student?`, and it
    # dereferences @portfolio, which stocks#index only assigns to a student who has one. The
    # trading floor 500'd rather than degrading.
    assert_text "Trading floor"
    assert_text "Apple Inc."

    columns = page.evaluate_script(<<~JS)
      (function () {
        const t = document.querySelector("table");
        return {
          head: t.querySelectorAll("thead th").length,
          body: t.querySelectorAll("tbody tr:first-child td").length
        };
      })()
    JS

    assert_equal columns["head"], columns["body"],
                 "header and row disagree on the column count for a student with no portfolio"
  end

  # A teacher and an admin hold no portfolio, so they get a read-only price list. Asserted so the
  # absence is understood as deliberate rather than rediscovered as a bug: design.md's note that
  # Buy/Sell keep their filled treatment is about the student-facing view only.
  test "a teacher sees the price list with no trade controls and no empty columns" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(teacher)

    visit stocks_path

    assert_text "Apple Inc."
    assert_no_selector "[data-testid='buy-stock-button']"
    assert_no_text "Your holdings"

    columns = page.evaluate_script(<<~JS)
      (function () {
        const t = document.querySelector("table");
        return {
          head: t.querySelectorAll("thead th").length,
          body: t.querySelectorAll("tbody tr:first-child td").length
        };
      })()
    JS

    assert_equal columns["head"], columns["body"],
                 "the header and the row disagree on how many columns the table has"
  end
end
