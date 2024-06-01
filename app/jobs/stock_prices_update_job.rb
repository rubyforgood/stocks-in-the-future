class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # For each stock symbol, request the latest closing cost
    # update the stocks table with each new closing cost
    stock_symbols = ["KO", "SNE", "TWX", "DIS", "SIRI", "F", "EA", "FB", "UA", "LUV", "GPS"]
    stock_symbols.each do |symbol|
      api_request(symbol)
      stock_db = Stock.find_by(ticker: symbol)
    end
  end

  private

  def api_request(symbol)
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    print Net::HTTP.get(uri)
  end
end
