require "json"
require "redis"

class Stocks::Price
  REDIS_HOST = "redis://redis:6379/"

  attr_accessor :open, :high, :low, :close, :volume,
    :adj_high, :adj_low, :adj_close, :adj_open, :adj_volume,
    :split_factor, :dividend, :symbol, :exchange, :date

  def assign_attrs(attrs = {})
    attrs.each_pair do |k, v|
      instance_variable_set("@#{k}", v) if v.present? && respond_to?(k)
    end
  end

  def initialize(attrs = {})
    assign_attrs(attrs) unless attrs.blank?
  end

  def get_end_of_day_price(symbol:, date: "latest")
    # date could be "latest" or "YYYY-MM-DD"
    redis = Redis.new(url: REDIS_HOST)
    cached = redis.get("eod_#{symbol.downcase}_#{date}")
    assign_attrs(JSON.parse(cached)) if cached.present?
  end

  def write_to_cache(is_latest: false, write_historic: false)
    return if @symbol.blank? || @close.blank? || @date.blank?
    # date could be "latest" or "YYYY-MM-DD"
    redis = Redis.new(url: REDIS_HOST)
    redis.set "eod_#{@symbol.downcase}_#{@date}", to_json if write_historic
    redis.set "eod_#{@symbol.downcase}_latest", to_json if is_latest
  end
end
