# frozen_string_literal: true

require "test_helper"

class StockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:stock).validate!
  end

  test "#current_price" do
    stock = create(:stock, price_cents: 1_000)

    result = stock.current_price

    assert_equal 10.0, result
  end

  test "archived defaults to false" do
    stock = create(:stock)

    assert_equal false, stock.archived
  end

  test "active and archived scopes filter correctly" do
    active_stock = create(:stock, archived: false)
    archived_stock = create(:stock, archived: true)

    active_stocks = Stock.active
    archived_stocks = Stock.archived

    assert_includes active_stocks, active_stock
    assert_not_includes active_stocks, archived_stock
    assert_includes archived_stocks, archived_stock
    assert_not_includes archived_stocks, active_stock
  end

  test "validates company_website format accepts valid http URLs" do
    stock = build(:stock, company_website: "http://example.com")

    assert stock.valid?
  end

  test "validates company_website format accepts valid https URLs" do
    stock = build(:stock, company_website: "https://example.com")

    assert stock.valid?
  end

  test "validates company_website format accepts blank URLs" do
    stock = build(:stock, company_website: "")

    assert stock.valid?
  end

  test "validates company_website format rejects javascript URLs" do
    stock = build(:stock, company_website: "javascript:alert('XSS')")

    assert_not stock.valid?
    assert stock.errors.added?(
      :company_website,
      "must be a valid HTTP or HTTPS URL"
    )
  end

  test "validates company_website format rejects invalid URLs" do
    stock = build(:stock, company_website: "not a url")

    assert_not stock.valid?
    assert stock.errors.added?(
      :company_website,
      "must be a valid HTTP or HTTPS URL"
    )
  end

  test "validates company_website format rejects data URLs" do
    stock = build(
      :stock,
      company_website: "data:text/html,<script>alert('XSS')</script>"
    )

    assert_not stock.valid?
    assert stock.errors.added?(
      :company_website,
      "must be a valid HTTP or HTTPS URL"
    )
  end

  # A mover has to have moved. The nav ticker this feeds the replacement for showed all 18 stocks at
  # 0.00% - none had a yesterday price - and coloured every one of them green with an up arrow.
  test "movers excludes stocks that have not moved" do
    create(:stock, ticker: "FLAT", price_cents: 10_000, yesterday_price_cents: 10_000)
    create(:stock, ticker: "NEW", price_cents: 10_000, yesterday_price_cents: nil)
    create(:stock, ticker: "ZERO", price_cents: 10_000, yesterday_price_cents: 0)
    moved = create(:stock, ticker: "MOVED", price_cents: 11_000, yesterday_price_cents: 10_000)

    assert_equal [moved], Stock.movers.to_a
  end

  test "movers orders by the size of the move, up or down" do
    small = create(:stock, ticker: "SMALL", price_cents: 10_100, yesterday_price_cents: 10_000)
    big_drop = create(:stock, ticker: "DROP", price_cents: 8_000, yesterday_price_cents: 10_000)
    medium = create(:stock, ticker: "MED", price_cents: 11_000, yesterday_price_cents: 10_000)

    # A 20% fall is a bigger move than a 10% rise, so direction does not decide the order.
    assert_equal [big_drop, medium, small], Stock.movers.to_a
  end

  test "movers leaves archived companies out and takes a limit" do
    create(:stock, ticker: "GONE", price_cents: 20_000, yesterday_price_cents: 10_000, archived: true)
    create_list(:stock, 4, price_cents: 11_000, yesterday_price_cents: 10_000)

    assert_not_includes Stock.movers(10).map(&:ticker), "GONE"
    assert_equal 3, Stock.movers.size
    assert_equal 2, Stock.movers(2).size
  end
end
