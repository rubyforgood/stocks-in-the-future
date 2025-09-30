# frozen_string_literal: true

require "net/http"
require "json"

class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(...)
    Rails.logger.info "Starting stock prices update job at #{Time.current}"

    stock_count = Stock.count
    Rails.logger.info "Found #{stock_count} stocks to update"

    return if stock_count.zero?

    updated_count = 0
    Stock.find_each do |stock|
      updated_count += 1 if update_stock_price(stock)
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
  rescue StandardError => e
    Rails.logger.error "Failed to update stock price for #{symbol}: #{e.message}"
  end

  def valid_stock_symbol?(stock, symbol)
    return true if symbol.present?

    Rails.logger.warn "Skipping stock with blank ticker: ID #{stock.id}"
    false
  end

  def update_stock_with_transaction(stock, symbol)
    Stock.transaction do
      stock.yesterday_price_cents = stock.price_cents
      process_price_update(stock, symbol)
    end
  end

  def process_price_update(stock, symbol)
    price = fetch_and_validate_price(symbol)
    return save_yesterday_price_only(stock, symbol) unless price

    save_updated_price(stock, symbol, price)
  end

  def save_yesterday_price_only(stock, symbol)
    stock.save!
    Rails.logger.warn "Could not fetch new price for #{symbol}, saved yesterday price only"
  end

  def save_updated_price(stock, symbol, price)
    stock.price_cents = convert_to_cents(price)
    stock.save!
    log_successful_update(stock, symbol)
    stock # Return the stock object (truthy)
  end

  def convert_to_cents(price)
    (price.to_f * 100).to_i
  end

  def log_successful_update(stock, symbol)
    Rails.logger.info "Updated #{symbol}: $#{stock.yesterday_price_cents / 100.0} -> " \
                      "$#{stock.price_cents / 100.0}"
  end

  def fetch_and_validate_price(symbol)
    data = api_request(symbol)
    price = data&.dig("Global Quote", "05. price")

    if price
      Rails.logger.info "API returned price #{price} for #{symbol}"
      price
    else
      Rails.logger.error "Invalid API response for #{symbol}: #{data}"
      nil
    end
  end

  def api_request(symbol)
    api_key = ENV.fetch("ALPHA_VANTAGE_API_KEY", nil)

    unless api_key
      Rails.logger.error "ALPHA_VANTAGE_API_KEY environment variable not configured"
      return nil
    end

    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{api_key}"
    uri = URI.parse(url)

    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse API response for #{symbol}: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "API request failed for #{symbol}: #{e.message}"
    nil
  end
end
