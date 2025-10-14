# frozen_string_literal: true

module ApplicationHelper
  def navbar_stocks
    Stock.active
  end

  def ticker_stocks
    Stock.active.order(:ticker)
  end

  def format_money(cents)
    format("$%.2f", cents / 100.0)
  end

  def safe_url(url)
    uri = URI.parse(url)
    %w[http https].include?(uri.scheme) ? url : nil
  rescue URI::InvalidURIError
    nil
  end
end
