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
end
