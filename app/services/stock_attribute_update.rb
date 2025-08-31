# frozen_string_literal: true

require "net/http"
require "json"

class StockAttributeUpdate
  def initialize(stock)
    @stock = stock
  end

  def self.execute(stock)
    new(stock).execute
  end

  def execute
    return if stock.ticker.blank?

    log_start_update
    data = fetch_api_data

    return unless valid_api_response?(data)

    update_stock_attributes(data)
    save_stock
  end

  private

  attr_reader :stock

  def log_start_update
    Rails.logger.info "Updating attributes for stock #{stock.ticker}"
  end

  def fetch_api_data
    api_request(stock.ticker)
  end

  def valid_api_response?(data)
    if data && data["Symbol"]
      Rails.logger.info "API returned data for #{stock.ticker}"
      true
    else
      Rails.logger.error "Invalid API response for #{stock.ticker}: #{data}"
      false
    end
  end

  def save_stock
    if stock.save
      Rails.logger.info "Successfully updated attributes for #{stock.ticker}"
    else
      Rails.logger.error "Failed to save #{stock.ticker}: #{stock.errors.full_messages}"
    end
  end

  def update_stock_attributes(data)
    update_basic_info(data)
    update_financial_info(data)
  end

  def update_basic_info(data)
    stock.company_name = data["Name"] if data["Name"]
    stock.description = data["Description"] if data["Description"]
    stock.stock_exchange = data["Exchange"] if data["Exchange"]
    stock.industry = data["Industry"] if data["Industry"]
  end

  def update_financial_info(data)
    stock.company_website = data["OfficialSite"] if data["OfficialSite"]
    stock.profit_margin = data["ProfitMargin"].to_f if data["ProfitMargin"]
  end

  def api_request(symbol)
    url = "https://www.alphavantage.co/query?function=OVERVIEW&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    JSON.parse Net::HTTP.get(uri)
  rescue JSON::ParserError, Net::HTTPError => e
    Rails.logger.error "API request failed for #{symbol}: #{e.message}"
    nil
  end
end
