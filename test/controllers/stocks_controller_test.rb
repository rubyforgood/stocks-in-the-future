# frozen_string_literal: true

require "test_helper"

class StocksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    admin = create(:admin)
    sign_in admin

    get stocks_url

    assert_response :success
  end

  test "should get show" do
    stock = create(:stock)
    admin = create(:admin)
    sign_in admin

    get stock_url(stock)

    assert_response :success
  end

  # This asserted a "Trade" link pointing at stocks_path, which was the whole problem: a stock's
  # own page could not act on that stock, and the link went to the same place as the "Back to
  # trading floor" button beside it. The page renders the trading floor's own Buy/Sell partial now,
  # so the action opens the order modal for this stock.
  test "a student who can trade gets Buy and Sell for this stock" do
    stock = create(:stock)
    student = create(:student, classroom: create(:classroom, :with_trading))
    create(:portfolio, user: student)
    sign_in student

    get stock_url(stock)

    assert_select "a[href=?]", new_order_path(stock_id: stock.id, transaction_type: :buy), text: "Buy"
    assert_select "a[href=?]", new_order_path(stock_id: stock.id, transaction_type: :sell), text: "Sell"
    assert_select "a[href='#{stocks_path}']", text: "Back to trading floor"
  end

  test "a teacher gets no trade action on a stock" do
    stock = create(:stock)
    sign_in create(:teacher)

    get stock_url(stock)

    assert_select "a", text: "Buy", count: 0
    assert_select "a", text: "Sell", count: 0
  end
  # Moved here from navbar_policy_visibility_test, which asserted these against the per-stock
  # sidebar list. The nav no longer carries a catalogue (migration.md, Map A), and this page is
  # where the stocks are - it also separates active from archived rather than hiding archived,
  # so the coverage is closer to the real behaviour than it was in the nav.
  # The archived list is a collapsed disclosure rather than a second titled table. It carried no
  # date, no explanation and an empty actions column for anything the viewer did not hold - which is
  # everything, for an admin - so it was a price list of things nobody on this page can buy, sitting
  # under the list of things they can. Still reachable, and still linking each stock to its page.
  test "index lists active stocks, and archived ones behind a disclosure" do
    active = create(:stock, archived: false, ticker: "AAPL")
    archived = create(:stock, archived: true, ticker: "DEAD")
    sign_in create(:admin)

    get stocks_url

    assert_response :success
    assert_select "h2", text: "Active stocks"
    assert_select "details[data-testid=?] summary", "archived-stocks", text: /Archived stocks \(1\)/
    assert_select "a[href=?]", stock_path(active), text: active.ticker
    assert_select "a[href=?]", stock_path(archived), text: archived.ticker
  end

  test "each table says what it is for" do
    create(:stock, archived: false, ticker: "AAPL")
    create(:stock, archived: true, ticker: "DEAD")
    sign_in create(:admin)

    get stocks_url

    # An admin cannot buy anything, so the list is not described to them in a buyer's voice. This
    # asserted the student sentence while signed in as an admin, and passed for as long as every role
    # was handed the same string.
    assert_select "p", text: /Companies your students can buy shares in right now/
    assert_select "details[data-testid=?]", "archived-stocks" do
      assert_select "p", text: /stopped trading here, so they cannot be bought/
      assert_select "p", text: /stay listed for #{Stock::LIST_RETENTION.inspect}/
    end
  end

  test "a student is the one told they can buy" do
    create(:stock, archived: false, ticker: "AAPL")
    sign_in create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    get stocks_url

    assert_select "p", text: /Companies you can buy shares in right now/
  end

  # Stock::LIST_RETENTION is a display rule, not a purge - orders and portfolio_stocks reference
  # stocks by id and restrict deletion, so the rows stay forever and the list is what ages.
  test "an archived stock past the retention window drops off the list" do
    old = create(:stock, archived: true, ticker: "GONE")
    old.update!(archived_at: (Stock::LIST_RETENTION + 1.day).ago)
    sign_in create(:admin)

    get stocks_url

    assert_select "a[href=?]", stock_path(old), count: 0
  end

  test "a stock you hold stays listed however long ago it was archived" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    old = create(:stock, archived: true, ticker: "GONE")
    old.update!(archived_at: (Stock::LIST_RETENTION + 1.day).ago)
    create(:portfolio_stock, portfolio: student.portfolio, stock: old, shares: 2)
    sign_in student

    get stocks_url

    assert_select "h2", text: "Archived stocks you hold"
    assert_select "a[href=?]", stock_path(old)
  end

  test "an archived row says why it is there" do
    create(:stock, archived: true, ticker: "DEAD", last_trading_day: Date.new(2026, 3, 12))
    sign_in create(:admin)

    get stocks_url

    assert_select "details[data-testid=?]", "archived-stocks" do
      assert_select "span", text: /No longer trading . last priced 12 Mar 2026/
    end
  end

  test "a student who holds an archived stock gets it surfaced with a sell action" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    dead = create(:stock, archived: true, ticker: "DEAD")
    create(:portfolio_stock, portfolio: student.portfolio, stock: dead, shares: 3)
    sign_in student

    get stocks_url

    assert_select "h2", text: "Archived stocks you hold"
    assert_select "a[data-testid=?]", "sell-stock-button"
    assert_select "a[data-testid=?]", "buy-stock-button", count: 0
  end

  test "index links each stock to its own page" do
    stock = create(:stock, archived: false, ticker: "GOOGL")
    sign_in create(:student, :with_portfolio)

    get stocks_url

    assert_response :success
    assert_select "a[href=?]", stock_path(stock), text: stock.ticker
  end
end
