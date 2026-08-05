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

  def surfaces
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("main .tw-card, main .table-wrapper")).map(function (c) {
        const b = c.getBoundingClientRect();
        return {
          left: Math.round(b.left),
          right: Math.round(b.right),
          width: Math.round(b.width),
          height: Math.round(b.height),
          radius: getComputedStyle(c).borderTopLeftRadius
        };
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
      radii = surfaces.pluck("radius").uniq

      assert_equal 1, radii.size,
                   "the page mixes #{radii.size} corner radii (#{radii.join(', ')}); a card and a " \
                   "table card are both panels, so both are rounded-2xl"
    end
  end

  test "the four headline figures are one equal band" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)
      kpis = surfaces.first(4)

      assert_equal 1, kpis.pluck("width").uniq.size, "the KPI cards are different widths"
      assert_equal 1, kpis.pluck("height").uniq.size, "the KPI cards are different heights"

      kpis.each_cons(2) do |left, right|
        assert_equal GUTTER, right["left"] - left["right"], "the KPI gutter is not 24px"
      end
    end
  end

  test "cards sharing a row share a height, and rows share their edges" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)
      all = surfaces
      chart = all[4]
      breakdown = all[5]
      table = all[6]

      assert_equal chart["height"], breakdown["height"],
                   "the chart and the breakdown are different heights in the same row; a grid " \
                   "cell stretches but the card inside it needs h-full"
      assert_equal GUTTER, breakdown["left"] - chart["right"], "the row 2 gutter is not 24px"

      # Every row starts and ends on the same two edges.
      assert_equal [all[0]["left"], chart["left"], table["left"]].uniq.size, 1,
                   "the rows do not share a left edge"
      assert_equal [all[3]["right"], breakdown["right"], table["right"]].uniq.size, 1,
                   "the rows do not share a right edge"
    end
  end

  test "the holdings table gets the full width" do
    sign_in(student_portfolio)

    in_chromebook_viewport do
      visit user_portfolio_path(student_portfolio, student_portfolio.portfolio)
      all = surfaces

      assert_operator all[6]["width"], :>, all[4]["width"],
                      "the holdings table is narrower than the chart; it has six columns and was " \
                      "the reason the page was hard to parse"
    end
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
