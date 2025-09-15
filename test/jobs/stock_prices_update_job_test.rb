# frozen_string_literal: true

require "test_helper"

class StockPricesUpdateJobTest < ActiveJob::TestCase
  STOCK_URL_MATCHER = %r{https://www\.alphavantage\.co/query\?apikey=[^&]+&function=GLOBAL_QUOTE&symbol=[A-Z]+}

  setup do
    stub_request(:get, STOCK_URL_MATCHER)
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "www.alphavantage.co",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: Rails.root.join("./test/data/global_quote_f.json").open)
  end

  test "makes API calls" do
    create(:stock, ticker: "AAPL")
    create(:stock, ticker: "KO")

    StockPricesUpdateJob.perform_now
    assert_requested :get, STOCK_URL_MATCHER, times: 2
  end

  test "updates existing Stock records" do
    stock1 = create(:stock, ticker: "AAPL", price_cents: 0)
    stock2 = create(:stock, ticker: "KO", price_cents: 0)

    assert_no_difference("Stock.count") do
      StockPricesUpdateJob.perform_now
    end

    stock1.reload
    stock2.reload
    assert stock1.price_cents.positive?
    assert stock2.price_cents.positive?
  end

  test "sets Stock ticker and price" do
    test_tickers = %w[AAPL KO DIS]
    test_tickers.each { |ticker| create(:stock, ticker: ticker, price_cents: 0) }

    StockPricesUpdateJob.perform_now
    test_tickers.each do |ticker|
      stock = Stock.find_by(ticker: ticker)
      assert stock.present?
      assert stock.price_cents.present?
    end
  end

  test "handles empty stock database gracefully" do
    # Ensure no stocks exist
    Stock.delete_all

    assert_no_difference("Stock.count") do
      assert_nothing_raised do
        StockPricesUpdateJob.perform_now
      end
    end

    assert_not_requested :get, STOCK_URL_MATCHER
  end

  test "stores current price as yesterday price before updating" do
    initial_price = 12_345
    stock = create(:stock, ticker: "AAPL", price_cents: initial_price, yesterday_price_cents: nil)

    StockPricesUpdateJob.perform_now

    stock.reload
    assert_equal initial_price, stock.yesterday_price_cents
    assert_not_equal initial_price, stock.price_cents
  end

  test "preserves yesterday price when API call fails" do
    initial_price = 12_345
    stock = create(:stock, ticker: "AAPL", price_cents: initial_price, yesterday_price_cents: nil)

    stub_request(:get, STOCK_URL_MATCHER).to_return(status: 200, body: "{}")

    StockPricesUpdateJob.perform_now

    stock.reload
    assert_equal initial_price, stock.yesterday_price_cents
    assert_equal initial_price, stock.price_cents
  end
end
