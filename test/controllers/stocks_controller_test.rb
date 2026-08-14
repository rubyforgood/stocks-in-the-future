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
    # The trail, not a back button: it says the same journey and one level more, and two controls to
    # `stocks_path` on one page is the duplication the header already lost once.
    assert_select "nav[aria-label='Breadcrumb'] a[href='#{stocks_path}']", text: "Trading floor"
    assert_select "a", { text: "Back to trading floor", count: 0 }
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
  # An archived stock appears only to someone who holds it, because selling it is the only action the
  # data supports. It used to be listed for every reader behind a disclosure - a price list of companies
  # nobody on the page can buy, retained for a year, which never answered who opened it or to do what.
  test "index lists active stocks, and no archived ones for a reader who holds none" do
    active = create(:stock, archived: false, ticker: "AAPL")
    archived = create(:stock, archived: true, ticker: "DEAD")
    sign_in create(:admin)

    get stocks_url

    assert_response :success
    assert_select "h2", text: "Active stocks"
    assert_select "a[href=?]", stock_path(active), text: active.ticker
    assert_select "a[href=?]", stock_path(archived), count: 0
    assert_select "details[data-testid=?]", "archived-stocks", count: 0
  end

  # **Decision B, and it is the negative that carries it.** Four tests cover a holder seeing their
  # archived stock; none covered the reader who holds none, which is nearly every reader and the whole
  # content of the rule. Reinstating the old "Archived stocks (N)" disclosure would pass every one of the
  # positive tests and fail these two.
  test "a student who holds none of them sees no archived section at all" do
    dead = create(:stock, archived: true, ticker: "DEAD", price_cents: 100)
    create(:stock, archived: false, ticker: "AAPL", price_cents: 200)
    sign_in create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    get stocks_url

    assert_select "h2", text: "Active stocks"
    assert_select "h2", text: /Archived/, count: 0
    assert_select "a[href=?]", stock_path(dead), count: 0
  end

  # A teacher holds nothing, so the same rule hides it from them - and unlike an admin they have no other
  # view of it, because `Admin::BaseController#authenticate_admin` redirects any non-admin away from
  # `/admin/stocks`. That is a real consequence of this rule rather than an accident; see design.md.
  test "a teacher sees no archived section either" do
    dead = create(:stock, archived: true, ticker: "DEAD", price_cents: 100)
    create(:stock, archived: false, ticker: "AAPL", price_cents: 200)
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    get stocks_url

    assert_select "h2", text: /Archived/, count: 0
    assert_select "a[href=?]", stock_path(dead), count: 0
  end

  test "a student who holds an archived stock still sees it, so they can sell" do
    archived = create(:stock, archived: true, ticker: "DEAD", price_cents: 100)
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    student.portfolio.portfolio_stocks.create!(stock: archived, shares: 2, purchase_price: 1)
    sign_in student

    get stocks_url

    assert_select "h2", text: "Archived stocks you hold"
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
  end

  test "a student is the one told they can buy" do
    create(:stock, archived: false, ticker: "AAPL")
    sign_in create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    get stocks_url

    assert_select "p", text: /Companies you can buy shares in right now/
  end

  # Stock::LIST_RETENTION is a display rule, not a purge - orders and portfolio_stocks reference stocks
  # by id and restrict deletion, so the rows stay forever and the list is what ages. It governs the admin
  # list now; the trading floor shows an archived stock only to a holder, however long ago it closed,
  # because they must always be able to sell it.
  test "a holder keeps seeing a stock archived long past the retention window" do
    old = create(:stock, archived: true, ticker: "GONE", price_cents: 100)
    old.update!(archived_at: (Stock::LIST_RETENTION + 1.day).ago)
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    student.portfolio.portfolio_stocks.create!(stock: old, shares: 1, purchase_price: 1)
    sign_in student

    get stocks_url

    assert_select "a[href=?]", stock_path(old), text: old.ticker
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
    dead = create(
      :stock, archived: true, ticker: "DEAD", last_trading_day: Date.new(2026, 3, 12),
              price_cents: 100
    )
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    student.portfolio.portfolio_stocks.create!(stock: dead, shares: 1, purchase_price: 1)
    sign_in student

    get stocks_url

    assert_select "span", text: /No longer trading . last priced 12 Mar 2026/
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
