require "net/http"
require "json"

# Get stock prices from api with:
# api = Stocks::MarketstackApi.new(api_key: Rails.application.credentials.marketstack_key)
# api.get_end_of_day_price(symbols: "KO,SNE,TWX,DIS,SIRI,F,EA,FB,UA,LUV,GPS")

class Stocks::MarketstackApi
  MARKETSTACK_URI = URI("http://api.marketstack.com/v1/eod")

  attr_reader :api_key

  def initialize(api_key: nil)
    @api_key = api_key
  end

  # date could be "latest" or "YYYY-MM-DD"
  def get_end_of_day_price(symbols:, date: "latest")
    return if symbols.blank? || api_key.blank?
    MARKETSTACK_URI.query = URI.encode_www_form(uri_params(symbols, date))
    json = Net::HTTP.get(MARKETSTACK_URI)
    api_response = JSON.parse(json)
    parsed = parse_eod_response(api_response["data"])
    parsed.each { |stock_price| stock_price.write_to_cache(is_latest: true) }
  end

  def parse_eod_response(prices)
    prices.map { |price| Stocks::Price.new(price) }
  end

  private

  def uri_params(symbols, date)
    {
      access_key: api_key,
      date: date,
      limit: symbols.count(",") + 1,
      symbols: symbols
    }
  end
end

# Sample api response
# {"pagination"=>{"limit"=>2, "offset"=>0, "count"=>2, "total"=>502},
#  "data"=>
#   [{"open"=>129.69,
#     "high"=>133.01,
#     "low"=>129.33,
#     "close"=>132.21,
#     "volume"=>46234700.0,
#     "adj_high"=>133.01,
#     "adj_low"=>129.33,
#     "adj_close"=>132.21,
#     "adj_open"=>129.69,
#     "adj_volume"=>46317381.0,
#     "split_factor"=>1.0,
#     "dividend"=>0.0,
#     "symbol"=>"AMZN",
#     "exchange"=>"XNAS",
#     "date"=>"2023-07-28T00:00:00+0000"},
#    {"open"=>130.97,
#     "high"=>134.07,
#     "low"=>130.92,
#     "close"=>133.01,
#     "volume"=>26971011.0,
#     "adj_high"=>134.07,
#     "adj_low"=>130.92,
#     "adj_close"=>133.01,
#     "adj_open"=>130.97,
#     "adj_volume"=>26971011.0,
#     "split_factor"=>1.0,
#     "dividend"=>0.0,
#     "symbol"=>"GOOG",
#     "exchange"=>"XNAS",
#     "date"=>"2023-07-28T00:00:00+0000"}]}
