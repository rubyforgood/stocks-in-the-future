# frozen_string_literal: true

require "test_helper"

class StockAttributeUpdateTest < ActiveSupport::TestCase
  test "updates stock attributes from valid API response" do
    stock = create(:stock, ticker: "TEST")

    mock_response = {
      "Symbol" => "TEST",
      "Name" => "Test Company",
      "Description" => "A test company description",
      "Exchange" => "NYSE",
      "Industry" => "TECHNOLOGY",
      "OfficialSite" => "https://test.com",
      "ProfitMargin" => "0.15"
    }

    Net::HTTP.expects(:get).returns(mock_response.to_json)

    StockAttributeUpdate.execute(stock)
    stock.reload

    assert_equal "Test Company", stock.company_name
    assert_equal "A test company description", stock.description
    assert_equal "NYSE", stock.stock_exchange
    assert_equal "TECHNOLOGY", stock.industry
    assert_equal "https://test.com", stock.company_website
    assert_equal 0.15, stock.profit_margin
  end

  test "handles invalid API response gracefully" do
    stock = create(:stock, ticker: "INVALID")

    Net::HTTP.expects(:get).returns("{}")

    original_updated_at = stock.updated_at

    StockAttributeUpdate.execute(stock)
    stock.reload

    assert_equal original_updated_at, stock.updated_at
  end

  test "handles API error gracefully" do
    stock = create(:stock, ticker: "ERROR")

    Net::HTTP.expects(:get).raises(JSON::ParserError.new("Invalid JSON"))

    original_updated_at = stock.updated_at

    StockAttributeUpdate.execute(stock)
    stock.reload

    assert_equal original_updated_at, stock.updated_at
  end

  test "skips stock without ticker" do
    stock = Stock.new(description: "Test stock")
    stock.save(validate: false)

    Net::HTTP.expects(:get).never

    StockAttributeUpdate.execute(stock)
    stock.reload

    assert_nil stock.company_name
  end

  test "handles API response with missing fields" do
    stock = create(:stock, ticker: "PARTIAL")

    mock_response = {
      "Symbol" => "PARTIAL",
      "Name" => "Partial Company"
    }

    Net::HTTP.expects(:get).returns(mock_response.to_json)

    StockAttributeUpdate.execute(stock)
    stock.reload

    assert_equal "Partial Company", stock.company_name
    assert_equal "A sample stock for testing", stock.description
    assert_equal "NYSE", stock.stock_exchange
  end
end
