# frozen_string_literal: true

class PortfolioPosition
  attr_reader :stock, :shares

  delegate :current_price, :price_cents, :ticker, :yesterday_price, to: :stock, prefix: :stock

  def initialize(stock:, shares:)
    @stock = stock
    @shares = shares
  end

  def current_value
    shares * stock_current_price
  end

  def current_value_cents
    shares * stock_price_cents
  end

  # TODO: how to handle when it's missing? NA?
  def stock_previous_close
    stock_yesterday_price || stock_current_price
  end

  def self.for_portfolio(portfolio)
    portfolio
      .portfolio_stocks
      .joins(:stock)
      .group(:stock)
      .having("SUM(portfolio_stocks.shares) > 0")
      .sum(:shares)
      .map { |stock, total_shares| new(stock: stock, shares: total_shares) }
  end
end
