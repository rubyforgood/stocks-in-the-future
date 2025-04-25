class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # For each stock symbol, request the latest closing cost
    # update the stocks table with each new closing cost
    stock_symbols = ["KO", "SNE", "TWX", "DIS", "SIRI", "F", "EA", "FB", "UA", "LUV", "GPS"]
    stock_symbols.each do |symbol|
      data = api_request(symbol)
      price = data["Global Quote"]["05. price"]
      stock = Stock.find_or_initialize_by(ticker: symbol)
      stock.price = price
      stock.save
    end
  end

  private

  def api_request(symbol)
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    JSON.parse Net::HTTP.get(uri)
  end
end
