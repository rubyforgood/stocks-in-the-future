class StockPricesUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # For each stock symbol, request the latest closing cost
    # update the stocks table with each new closing cost
    stock_symbols = ["KO", "SNE", "TWX", "DIS", "SIRI", "F", "EA", "FB", "UA", "LUV", "GPS"]
    stock_symbols.each do |symbol|
      data = api_request(symbol)
      price = data["Global Quote"]["05. price"]
      stock_rec = Stock.find_by(ticker: symbol)
      if stock_rec
          stock_rec.price = price
          stock_rec.save
      else
          stock_rec = Stock.new
          stock_rec.ticker = symbol
          stock_rec.price = price
          stock_rec.save
      end
    end 
  end

  private 

  def api_request(symbol)
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=#{symbol}&apikey=#{API_KEY}"
    uri = URI.parse(url)
    return JSON.parse Net::HTTP.get(uri)
  end 
end

