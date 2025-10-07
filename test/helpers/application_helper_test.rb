# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "navbar_stocks returns only active stocks" do
    create(:stock, archived: false, ticker: "AAPL")
    create(:stock, archived: false, ticker: "DIS")
    archived_stock = create(:stock, archived: true, ticker: "DEAD")

    result = navbar_stocks

    assert_equal result, Stock.active
    assert_not_includes result, archived_stock
  end
end