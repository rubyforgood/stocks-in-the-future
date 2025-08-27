# frozen_string_literal: true

require "net/http"
require "json"

class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/AbcSize
  def perform(...)
    # For each stock symbol, request the latest closing cost
    # update the stocks table with each new closing cost
    Stock::SYMBOLS.each do |symbol|
      Rails.logger.info "Updating stock price for #{symbol}"

      data = api_request(symbol)

      # Check if API returned valid data
      price = data&.dig("Global Quote", "05. price")
      unless price
        Rails.logger.error "Invalid API response for #{symbol}: #{data}"
        next
      end
      Rails.logger.info "API returned price #{price} for #{symbol}"

      stock = Stock.find_or_initialize_by(ticker: symbol)
      old_price = stock.price_cents

      # Convert price to cents
      stock.price_cents = (price.to_f * 100).to_i
      Rails.logger.info "Converting #{symbol} price from #{old_price} to #{stock.price_cents} cents"

      # Save with error handling
      if stock.save
        Rails.logger.info "Successfully updated #{symbol} price to $#{stock.current_price}"
      else
        Rails.logger.error "Failed to save #{symbol}: #{stock.errors.full_messages}"
      end
    end
  end

  # rubocop:enable Metrics/AbcSize

  private

  def api_request(symbol)
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    JSON.parse Net::HTTP.get(uri)
  end
end
