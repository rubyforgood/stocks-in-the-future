class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # For each stock symbol, request the latest closing cost
    # update the stocks table with each new closing cost
  end
end
