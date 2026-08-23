# frozen_string_literal: true

class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(...)
    Rails.logger.info "Starting stock prices update job at #{Time.current}"
    @api_client = AlphaVantageApiClient.new

    stock_count = Stock.count
    Rails.logger.info "Found #{stock_count} stocks to update"

    return if stock_count.zero?

    updated_count = 0
    Stock.find_each do |stock|
      updated_count += 1 if update_stock_price(stock)
      sleep(1.1) # To rate limit
    end

    Rails.logger.info "Stock prices update job completed: #{updated_count}/#{stock_count} stocks updated successfully"
  rescue StandardError => e
    Rails.logger.error "Stock prices update job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def update_stock_price(stock)
    symbol = stock.ticker
    return false unless valid_stock_symbol?(stock, symbol)

    Rails.logger.debug { "Updating stock price for #{symbol}" }
    update_stock_with_transaction(stock, symbol)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to save #{symbol}: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "Failed to update stock price for #{symbol}: #{e.message}"
    false
  end

  def valid_stock_symbol?(stock, symbol)
    return true if symbol.present?

    Rails.logger.warn "Skipping stock with blank ticker: ID #{stock.id}"
    false
  end

  # `yesterday_price_cents` is **not** assigned here. It used to be, before the fetch, which meant an API
  # failure saved `yesterday = today` and destroyed the real comparison point: a stock at 110 against
  # yesterday's 100 came out of a failed run reporting **0.00%** instead of +10.00%, which is exactly what a
  # genuinely flat day looks like. Every failure mode in AlphaVantageApiClient returns nil rather than
  # raising - no API key, network error, parse error, invalid response - so `retry_on` never fired and
  # nothing anywhere said the number was fabricated.
  #
  # It is set in `save_updated_price` now, where a new price is actually being written, so "yesterday" only
  # ever means the price this one replaced.
  def update_stock_with_transaction(stock, symbol)
    Stock.transaction do
      process_price_update(stock, symbol)
    end
  end

  def process_price_update(stock, symbol)
    price_data = @api_client.fetch_quote(symbol)
    return no_price_available(stock, symbol) unless price_data

    unless should_update?(stock, price_data[:trading_day])
      Rails.logger.info "Skipping #{symbol}: no trading since #{stock.last_trading_day}"
      return false
    end

    save_updated_price(stock, symbol, price_data[:price], price_data[:trading_day])
  end

  # Nothing is written. There is no new price, so there is nothing true to record - and writing the old
  # price into `yesterday_price_cents` (which this used to do) turned "we could not reach the market" into
  # "the price did not move", which is a different claim and a false one.
  #
  # `last_trading_day` is left alone too, which is what lets the trading floor tell that the price it is
  # showing is not today's.
  def no_price_available(stock, symbol)
    Rails.logger.warn "Could not fetch a new price for #{symbol}; leaving #{stock.ticker} untouched " \
                      "(last priced #{stock.last_trading_day || 'never'})"
    nil
  end

  def should_update?(stock, latest_trading_day)
    stock.last_trading_day.nil? || latest_trading_day.to_date > stock.last_trading_day
  end

  def save_updated_price(stock, symbol, price, trading_day)
    # Assigned here and only here: yesterday's price is the one this call is replacing.
    stock.yesterday_price_cents = stock.price_cents
    stock.price_cents = convert_to_cents(price)
    stock.last_trading_day = trading_day.to_date
    stock.save!
    log_successful_update(stock, symbol)
    stock # Return the stock object (truthy)
  end

  def convert_to_cents(price)
    (price.to_f * 100).to_i
  end

  def log_successful_update(stock, symbol)
    yesterday_price = stock.yesterday_price_cents.to_f / 100.0
    current_price = stock.price_cents.to_f / 100.0
    Rails.logger.info "Updated #{symbol}: $#{yesterday_price} -> $#{current_price}"
  end
end
