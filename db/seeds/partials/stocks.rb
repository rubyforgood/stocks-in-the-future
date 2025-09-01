# frozen_string_literal: true

SEED_TICKERS = %w[AAPL KO SONY DIS SIRI F EA META LUV GAP VZ].freeze

SEED_TICKERS.each do |ticker|
  Stock.find_or_create_by(ticker: ticker)
end

StockPricesUpdateJob.perform_now
StockAttributeUpdateJob.perform_now
