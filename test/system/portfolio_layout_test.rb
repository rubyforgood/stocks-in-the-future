# frozen_string_literal: true

require "application_system_test_case"

# The portfolio page's geometry, measured.
#
# It was reported as busy and poorly laid out, with the table squeezed to one side and nothing
# lining up. Measured, that was four things at once:
#
#   - Three gutters on one screen: gap-8 between the columns, gap-6 inside them, gap-4 between the
#     stats.
#   - Five card surfaces: .tw-card, _stat's own rounded-xl/shadow-xs, the earnings-to-invest
#     panel's rounded-xl with an h-[150px], .table-wrapper's rounded-xl/shadow-xs, and a
#     hand-rolled amber alert. Two different corner radii sat directly above one another.
#   - A six-column holdings table in a two-thirds column while a narrow label/value list took the
#     other third, so the widest content had the least room.
#   - Cards in the same row at different heights, because the grid cell stretched and the card
#     inside it did not.
class PortfolioLayoutTest < ApplicationSystemTestCase
  GUTTER = 24

  # Selected by role, never by position: this test used positional indices and broke the moment a
  # row was inserted between the chart and the table, silently measuring the wrong cards.
  def region(selector)
    page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector(#{selector.to_json});
        if (!el) return null;
        const card = el.closest(".tw-card, .table-wrapper") || el;
        const b = card.getBoundingClientRect();
        return {
          left: Math.round(b.left),
          right: Math.round(b.right),
          width: Math.round(b.width),
          height: Math.round(b.height),
          radius: getComputedStyle(card).borderTopLeftRadius
        };
      })()
    JS
  end

  def kpis
    %w[portfolio-value cash-balance holdings-value total-stocks]
      .map { |id| region("[data-testid='#{id}']") }
  end

  def chart
    region("[data-controller='portfolio-chart'], canvas")
  end

  def breakdown
    region("dl")
  end

  def holdings
    region("[data-testid='holdings-table'] table")
  end

  def all_surfaces
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("main .tw-card, main .table-wrapper")).map(function (c) {
        return getComputedStyle(c).borderTopLeftRadius;
      })
    JS
  end

  def student_portfolio
    @student_portfolio ||= build_student_portfolio
  end

  def build_student_portfolio
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    # A reason-tagged deposit, so the summary and the personal best are not withheld: they render
    # only when a student has actually earned something.
    create(
      :portfolio_transaction, portfolio: student.portfolio, transaction_type: :deposit,
                              reason: :attendance_earnings, amount_cents: 1_500
    )
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 3)
    create(
      :portfolio_snapshot, portfolio: student.portfolio, date: 2.months.ago.to_date,
                           worth_cents: 90_000
    )
    create(
      :portfolio_snapshot, portfolio: student.portfolio, date: Date.current,
                           worth_cents: 120_000
    )
    student
  end

  test "every surface on the page shares one corner radius" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)
      radii = all_surfaces.uniq

      assert_equal 1, radii.size,
                   "the page mixes #{radii.size} corner radii (#{radii.join(', ')}); a card and a " \
                   "table card are both panels, so both are rounded-2xl"
    end
  end

  test "the four headline figures are one equal band" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)
      band = kpis

      assert_equal 1, band.pluck("width").uniq.size, "the KPI cards are different widths"
      assert_equal 1, band.pluck("height").uniq.size, "the KPI cards are different heights"

      band.each_cons(2) do |left, right|
        assert_equal GUTTER, right["left"] - left["right"], "the KPI gutter is not 24px"
      end
    end
  end

  test "cards sharing a row share a height, and rows share their edges" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

      assert_equal chart["height"], breakdown["height"],
                   "the chart and the breakdown are different heights in the same row; a grid " \
                   "cell stretches but the card inside it needs h-full"
      assert_equal GUTTER, breakdown["left"] - chart["right"], "the row 2 gutter is not 24px"

      lefts = [kpis.first["left"], chart["left"], holdings["left"]].uniq
      rights = [kpis.last["right"], breakdown["right"], holdings["right"]].uniq

      assert_equal 1, lefts.size, "the rows do not share a left edge: #{lefts.join(', ')}"
      assert_equal 1, rights.size, "the rows do not share a right edge: #{rights.join(', ')}"
    end
  end

  test "the holdings table gets the full width" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

      assert_operator holdings["width"], :>, chart["width"],
                      "the holdings table is narrower than the chart; it has six columns and was " \
                      "the reason the page was hard to parse"
    end
  end

  # Every card sharing a row shares a height, including the summary row. This is what stops a card
  # with more content padding out the bottom of its neighbours - a third card there, a wrapping
  # strip of company logos, was doing exactly that.
  test "the summary row shares a height too" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

      summary = region("[data-testid='best-month']")
      sentence = page.evaluate_script(<<~JS)
        (function () {
          const c = Array.from(document.querySelectorAll("main .tw-card"))
            .find(function (x) { return x.textContent.includes("Your money at work"); });
          if (!c) return null;
          const b = c.getBoundingClientRect();
          return { height: Math.round(b.height), width: Math.round(b.width) };
        })()
      JS

      assert_equal sentence["height"], summary["height"],
                   "the summary row's cards are different heights"
      assert_operator sentence["width"], :>, summary["width"],
                      "the sentence wants the width and the stat does not"
    end
  end

  # design.md's icon tile token: grid place-items-center h-9 w-9 rounded-xl bg-{semantic}-50.
  # Was "all on the 36px token", asserting 36px. The rule that actually holds across the app is
  # about what the tile stands next to, not which page it is on: a tile *beside* a line of 14px text
  # is 32px, because 36px out-heights the text it labels, and a tile on its *own* line above a
  # figure is 36px, which is what the admin dashboard does. These two cards sit beside their labels,
  # like the home page's balance card and every _card header, so they are 32px.
  test "icon tiles beside a label are all on the 32px token" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

      sizes = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("main .tw-card span.rounded-xl")).map(function (t) {
          const b = t.getBoundingClientRect();
          return Math.round(b.width) + "x" + Math.round(b.height);
        })
      JS

      assert_not_empty sizes, "expected at least one icon tile"
      assert_equal ["32x32"], sizes.uniq,
                   "a tile beside a label is size-8; #{sizes.uniq.join(', ')} means one was eyeballed"
    end
  end

  # A banner is text with a marker beside it, not a card whose subject is an icon.
  test "the first-share banner uses a plain glyph and the brand-safe info tint" do
    sign_in(student_portfolio)
    visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

    banner = page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector("[data-testid='first-share']");
        if (!el) return null;
        return {
          tile: !!el.querySelector("span.rounded-xl"),
          bg: getComputedStyle(el).backgroundColor
        };
      })()
    JS

    assert_not_nil banner, "expected the first-share banner"
    assert_not banner["tile"],
               "a message bar gets a plain glyph, never an icon tile - the tile pattern assumes " \
               "a white surface and a subject, and a banner is neither"
    # blue-50. Tailwind's teal-50 is a mint green and is not this product's brand, which is
    # sitf-primary #00698c.
    assert_equal "oklch(0.97 0.014 254.604)", banner["bg"],
                 "the banner is not on the callout's info tint"
  end

  # The figures decompose the total rather than repeating it.
  test "the headline figures are value, cash, invested and a count" do
    sign_in(student_portfolio)
    visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)

    assert_selector "[data-testid='portfolio-value']", text: "Portfolio value"
    assert_selector "[data-testid='cash-balance']", text: "Cash to invest"
    assert_selector "[data-testid='holdings-value']", text: "Invested"
    assert_selector "[data-testid='total-stocks']", text: "Shares held"
  end
end
