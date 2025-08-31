# frozen_string_literal: true

class StockAttributeUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Stock.find_each do |stock|
      Rails.logger.info "Processing stock attribute update for #{stock.ticker}"

      StockAttributeUpdate.execute(stock)
    end
  end
end
