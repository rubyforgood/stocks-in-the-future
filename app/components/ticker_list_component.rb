class TickerListComponent < ViewComponent::Base
  STOCK_SYMBOLS = {
    KO: "Coca-Cola Company",
    SNE: "Sony Corporation",
    TWX: "Time Warner",
    DIS: "Walt Disney",
    SIRI: "Sirius XM Satellite Radio",
    F: "Ford",
    EA: "Electronic Arts",
    FB: "Facebook",
    UA: "Under Armour",
    LUV: "Southwest Airlines",
    GPS: "Gap Inc."
  }

  def stocks
    STOCK_SYMBOLS.keys.map do |symbol|
      price = Stocks::Price.new
      price.get_end_of_day_price(symbol: symbol.downcase)
      if price.close.present?
        {
          change: BigDecimal(price.open.to_s) - BigDecimal(price.close.to_s),
          name: STOCK_SYMBOLS[symbol],
          price: price.close,
          ticker: symbol
        }
      end
    end.compact
  end
end
