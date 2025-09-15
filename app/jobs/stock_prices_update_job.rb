# frozen_string_literal: true

require "net/http"
require "json"

class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  def perform(...)
    Stock.find_each { |stock| update_stock_price(stock) }
  end

  private

  def update_stock_price(stock)
    symbol = stock.ticker
    return if symbol.blank?

    Rails.logger.info "Updating stock price for #{symbol}"

    Stock.transaction do
      stock.yesterday_price_cents = stock.price_cents

      price = fetch_and_validate_price(symbol)
      unless price
        stock.save!
        return
      end

      # Converting to cents
      stock.price_cents = (price.to_f * 100).to_i

      stock.save!
      Rails.logger.info "Successfully updated #{symbol} price from #{stock.yesterday_price_cents} to #{stock.price_cents} ($#{stock.current_price})"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to save #{symbol}: #{e.message}"
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
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    JSON.parse Net::HTTP.get(uri)
  end
end
