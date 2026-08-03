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

  test "trade stock button links to trading floor for students" do
    stock = create(:stock)
    student = create(:student)
    create(:portfolio, user: student)
    sign_in student

    get stock_url(stock)

    assert_select "a[href='#{stocks_path}']", text: "Trade stock"
  end
  # Moved here from navbar_policy_visibility_test, which asserted these against the per-stock
  # sidebar list. The nav no longer carries a catalogue (migration.md, Map A), and this page is
  # where the stocks are - it also separates active from archived rather than hiding archived,
  # so the coverage is closer to the real behaviour than it was in the nav.
  test "index lists active and archived stocks in separate labelled tables" do
    active = create(:stock, archived: false, ticker: "AAPL")
    archived = create(:stock, archived: true, ticker: "DEAD")
    sign_in create(:admin)

    get stocks_url

    assert_response :success
    assert_select "h2", text: "Active stocks"
    assert_select "h2", text: "Archived stocks"
    assert_select "a[href=?]", stock_path(active), text: active.ticker
    assert_select "a[href=?]", stock_path(archived), text: archived.ticker
  end

  test "index links each stock to its own page" do
    stock = create(:stock, archived: false, ticker: "GOOGL")
    sign_in create(:student, :with_portfolio)

    get stocks_url

    assert_response :success
    assert_select "a[href=?]", stock_path(stock), text: stock.ticker
  end
end
