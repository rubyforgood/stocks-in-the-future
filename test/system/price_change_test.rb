# frozen_string_literal: true

require "application_system_test_case"

# Price change, in the one place it belongs: beside the price, in the table a student buys from.
#
# It had three homes in as many commits and is now gone, and the reasons are worth keeping. It was a
# scrolling ticker in the header - WCAG 2.2.2 at Level A with no pause control, colours at 2.74:1 and 3.78:1, and
# every stock
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

  # The Change column is gone - see design.md for the four reasons. What replaced it is the age of the price,
  # which bears on the transaction rather than on the browsing: a student places an order against this
  # number.
  test "there is no change column" do
    a_student_with_stocks
    create(
      :stock, ticker: "UP", company_name: "Riser", price_cents: 11_000, yesterday_price_cents: 10_000,
              last_trading_day: Date.current - 1
    )

    visit stocks_path

    assert_no_selector "th", text: "Change"
    assert_no_text "+10.00%"
  end

  # Stale means "older than the freshest price on this page", which needs no calendar knowledge - and that
  # matters, because the job runs at 02:00 for the previous close, so a fresh price normally carries
  # yesterday's date. Comparing against today would mark every row.
  test "a price behind the freshest one on the page says how old it is" do
    a_student_with_stocks
    create(
      :stock, ticker: "FRESH", company_name: "Up To Date", price_cents: 10_000,
              yesterday_price_cents: 9_900, last_trading_day: Date.current - 1
    )
    create(
      :stock, ticker: "OLD", company_name: "Left Behind", price_cents: 5_000,
              yesterday_price_cents: 4_900, last_trading_day: Date.current - 5
    )

    visit stocks_path

    rows = page.evaluate_script(<<~JS)
      (function () {
        const out = {};
        document.querySelectorAll("main tbody tr").forEach(function (tr) {
          const name = tr.textContent.replace(/\s+/g, " ").trim();
          const price = tr.querySelectorAll("td")[1];
          const note = price ? price.querySelector("span.text-xs") : null;
          if (name.includes("Up To Date")) out.fresh = note ? note.textContent.trim() : null;
          if (name.includes("Left Behind")) out.stale = note ? note.textContent.trim() : null;
        });
        return out;
      })()
    JS

    assert_nil rows["fresh"], "the freshest price carries a date it does not need: #{rows['fresh']}"
    assert_equal "as of #{(Date.current - 5).strftime('%-d %b')}", rows["stale"]
  end

  test "a company that has never been priced says so" do
    a_student_with_stocks
    create(
      :stock, ticker: "NEW", company_name: "Never Priced", price_cents: 1_250,
              yesterday_price_cents: nil, last_trading_day: nil
    )

    visit stocks_path

    assert_text "Not priced yet"
  end

  # When every price is behind, no row is marked and the page carries the date. "Prices as of 3 August" is
  # the fact; "every company is stale" is not.
  test "the page states how old its prices are, once" do
    a_student_with_stocks
    create(:stock, ticker: "A", company_name: "Alpha", price_cents: 10_000, last_trading_day: Date.current - 4)
    create(:stock, ticker: "B", company_name: "Beta", price_cents: 20_000, last_trading_day: Date.current - 4)

    visit stocks_path

    assert_text "Prices are updated once a day, after the market closes."
    assert_text "as of #{I18n.l(Date.current - 4, format: :long)}"
    assert_no_selector "span", text: "as of #{(Date.current - 4).strftime('%-d %b')}"
  end

  test "a floor with no priced companies at all says that instead of a date" do
    a_student_with_stocks
    create(:stock, ticker: "NEW", company_name: "Never Priced", price_cents: 1_250, last_trading_day: nil)

    visit stocks_path

    assert_text "Prices have not been updated yet."
  end

  # Buy and Sell: bordered secondary buttons, not ghosts and not filled, and with no icons - in a finance
  # interface a vertical arrow means the price moved that way, which is not what a button does.
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

  # The caution about a big move went with the column it described - the thing it cautioned against is no
  # longer on the screen.
  test "the page no longer cautions about a figure it does not show" do
    a_student_with_stocks

    visit stocks_path

    assert_no_text "does not make a company a better buy"
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
