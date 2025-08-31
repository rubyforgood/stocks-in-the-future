# frozen_string_literal: true

require "test_helper"

class StockAttributeUpdateJobTest < ActiveJob::TestCase
  test "processes all stocks in the database" do
    stock1 = create(:stock, ticker: "STOCK1")
    stock2 = create(:stock, ticker: "STOCK2")
    stock3 = create(:stock, ticker: "STOCK3")

    Net::HTTP.expects(:get).times(3).returns(
      { "Symbol" => "STOCK1", "Name" => "Company 1" }.to_json,
      { "Symbol" => "STOCK2", "Name" => "Company 2" }.to_json,
      { "Symbol" => "STOCK3", "Name" => "Company 3" }.to_json
    )

    StockAttributeUpdateJob.perform_now

    stock1.reload
    stock2.reload
    stock3.reload

    assert_equal "Company 1", stock1.company_name
    assert_equal "Company 2", stock2.company_name
    assert_equal "Company 3", stock3.company_name
  end

  test "handles stocks with invalid API responses" do
    stock1 = create(:stock, ticker: "VALID")
    stock2 = create(:stock, ticker: "INVALID")

    original_name = stock2.company_name

    Net::HTTP.expects(:get).times(2).returns(
      { "Symbol" => "VALID", "Name" => "Valid Company" }.to_json,
      "{}"
    )

    StockAttributeUpdateJob.perform_now

    stock1.reload
    stock2.reload

    assert_equal "Valid Company", stock1.company_name
    assert_equal original_name, stock2.company_name
  end

  test "skips stocks without ticker" do
    stock_with_ticker = create(:stock, ticker: "HAS_TICKER")
    stock_without_ticker = Stock.new(description: "Test stock")
    stock_without_ticker.save(validate: false)

    Net::HTTP.expects(:get).once.returns(
      { "Symbol" => "HAS_TICKER", "Name" => "Has Ticker Company" }.to_json
    )

    StockAttributeUpdateJob.perform_now

    stock_with_ticker.reload
    stock_without_ticker.reload

    assert_equal "Has Ticker Company", stock_with_ticker.company_name
    assert_nil stock_without_ticker.company_name
  end

  test "handles empty stock table" do
    Stock.delete_all
    Net::HTTP.expects(:get).never

    assert_nothing_raised do
      StockAttributeUpdateJob.perform_now
    end
  end
end
