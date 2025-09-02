# frozen_string_literal: true

class PortfolioStock < ApplicationRecord
  belongs_to :portfolio
  belongs_to :stock

  scope :aggregated_positions, lambda {
    joins(:stock)
      .group(:stock_id)
      .having("SUM(portfolio_stocks.shares) > 0")
      .select(
        "stock_id, " \
        "SUM(portfolio_stocks.shares) as total_shares, " \
        "SUM(portfolio_stocks.shares * portfolio_stocks.purchase_price) / SUM(portfolio_stocks.shares) as avg_price"
      )
      .order("MIN(stocks.ticker)")
  }

  # Calculate the earnings of a single share of the stock
  def calculate_earnings
    # based on purchase price
  end
end
