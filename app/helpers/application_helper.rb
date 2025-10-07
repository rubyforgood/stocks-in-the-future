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
end
