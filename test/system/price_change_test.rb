# frozen_string_literal: true

require "application_system_test_case"

# Price change, in the one place it belongs: beside the price, in the table a student buys from.
#
# It has had three homes in as many commits, and the reasons are worth keeping. It was a scrolling ticker in
# the header - WCAG 2.2.2 at Level A with no pause control, colours at 2.74:1 and 3.78:1, and every stock
# reading 0.00% and green because nothing had a yesterday price. Then a "Today's movers" card on the home
# page, which pushed the balance, the announcements and the getting-started steps down in order to list
# three of the companies the trading floor lists anyway. Now a column, which is where Robinhood, Fidelity,
# Schwab and E*TRADE all put it.
class PriceChangeTest < ApplicationSystemTestCase
  def a_student_with_stocks
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student
    student
  end

  test "no page animates anything, anywhere" do
    a_student_with_stocks
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)

    [root_path, stocks_path].each do |path|
      visit path

      assert_no_selector ".ticker-content", visible: :all
      assert_no_selector ".animate-scroll", visible: :all

      animating = page.evaluate_script(<<~JS)
        (function () {
          return Array.from(document.querySelectorAll("*"))
            .filter(function (el) { return getComputedStyle(el).animationName !== "none"; })
            .map(function (el) { return el.tagName.toLowerCase(); });
        })()
      JS

      assert_empty animating, "#{path} still animates: #{animating.join(', ')}"
    end
  end

  test "the trading floor shows a change beside each price" do
    a_student_with_stocks
    create(:stock, ticker: "UP", company_name: "Riser", price_cents: 11_000, yesterday_price_cents: 10_000)
    create(:stock, ticker: "DOWN", company_name: "Faller", price_cents: 9_000, yesterday_price_cents: 10_000)

    visit stocks_path

    assert_selector "th", text: "Change"

    rows = page.evaluate_script(<<~JS)
      (function () {
        return Array.from(document.querySelectorAll("main tbody tr")).map(function (tr) {
          const cells = tr.querySelectorAll("td");
          const change = cells[2];
          // The whole row's text: the primary cell leads with the ticker, so the first line is "UP", not
          // "Riser", and matching on the first line found nothing.
          return { name: tr.textContent.replace(/\s+/g, " ").trim(),
                   change: change ? change.textContent.replace(/\s+/g, " ").trim() : null,
                   arrows: change ? change.querySelectorAll("svg").length : 0,
                   colour: change ? getComputedStyle(change.querySelector("span") || change).color : null };
        });
      })()
    JS

    riser = rows.find { it["name"].include?("Riser") }
    faller = rows.find { it["name"].include?("Faller") }

    assert_equal "+10.00%", riser["change"]
    assert_equal "-10.00%", faller["change"]
    assert_not_equal riser["colour"], faller["colour"], "up and down are the same colour"

    # The arrow, which design.md specifies for this column and which the sign alone does not replace: it is
    # what makes the direction readable without reading. I shipped the column without it, and the preview
    # showed it, so the two disagreed.
    assert_equal 1, riser["arrows"], "the up figure has no arrow"
    assert_equal 1, faller["arrows"], "the down figure has no arrow"
  end

  # Buy and Sell are unchanged by the column beside them: bordered secondary buttons, not ghosts and not
  # filled, and with no icons - a vertical arrow means the price moved, which is the Change column's glyph
  # now, so the same one cannot also mean "place an order".
  test "buy and sell are still secondary buttons, with no arrows" do
    a_student_with_stocks
    create(:stock, ticker: "UP", company_name: "Riser", price_cents: 11_000, yesterday_price_cents: 10_000)

    visit stocks_path

    buy = page.evaluate_script(<<~JS)
      (function () {
        // The visible copy. `_trade_actions` renders twice - `lg:hidden` inside the primary cell and
        // `hidden lg:table-cell` in the actions column - so the first in the DOM is the one that is
        // display:none at this width, and measuring it reports a 0px button.
        const el = Array.from(document.querySelectorAll("[data-testid='buy-stock-button']"))
          .find(function (c) { return c.getClientRects().length > 0; });
        if (!el) return null;
        const box = el.getBoundingClientRect();
        return { classes: el.className, height: Math.round(box.height),
                 icons: el.querySelectorAll("svg").length, text: el.textContent.trim() };
      })()
    JS

    assert_not_nil buy, "no Buy control on the trading floor"
    assert_includes buy["classes"], "tw-btn-secondary"
    assert_equal "Buy", buy["text"]
    assert_in_delta 40, buy["height"], 2
    assert_equal 0, buy["icons"], "Buy carries an icon; the arrow belongs to the price, not the action"
  end

  # An archived company's price is frozen, so a change for it is arithmetic on a stale number.
  test "an archived company shows no change figure" do
    a_student_with_stocks
    create(
      :stock, ticker: "OLD", company_name: "Gone Away", price_cents: 5_000,
              yesterday_price_cents: 4_000, archived: true
    )

    visit stocks_path

    archived_change = page.evaluate_script(<<~JS)
      (function () {
        const row = Array.from(document.querySelectorAll("main tbody tr"))
          .find(function (tr) { return tr.textContent.includes("Gone Away"); });
        if (!row) return "no row";
        const cells = row.querySelectorAll("td");
        return cells[2] ? cells[2].textContent.trim() : "no cell";
      })()
    JS

    assert_equal "—", archived_change
  end

  # Below lg the column collapses into the primary cell, like the holdings and the trade buttons - adding a
  # third always-visible column would put this table back into a horizontal scroll at 375px.
  test "the change collapses into the primary cell at 375px" do
    a_student_with_stocks
    create(:stock, ticker: "UP", company_name: "Riser", price_cents: 11_000, yesterday_price_cents: 10_000)

    in_phone_viewport do
      visit stocks_path

      assert_text "+10.00% since yesterday"
      assert_no_selector "th", text: "Change"
    end
  end

  # The caution is on the page where the choice is made, not on the launchpad a student passed through.
  test "the trading floor says a big move is not a reason to buy" do
    a_student_with_stocks

    visit stocks_path

    assert_text "Prices update once a day"
    assert_text "does not make a company a better buy"
  end

  # And the home page is back to the three things it is for.
  test "the home page carries no movers card" do
    a_student_with_stocks
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)

    visit root_path

    assert_no_text "Today's movers"
    assert_text "Earnings to invest"
    assert_text "Announcements"
  end
end
