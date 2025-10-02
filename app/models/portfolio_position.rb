# frozen_string_literal: true

class PortfolioPosition
  attr_reader :stock, :shares, :portfolio, :change_amount, :total_return_amount

  delegate :current_price, :price_cents, :ticker, to: :stock, prefix: :stock

  def initialize(stock:, shares:, portfolio: nil, financial_data: {})
    @stock = stock
    @shares = shares
    @portfolio = portfolio
    @change_amount = financial_data[:change_amount]
    @total_return_amount = financial_data[:total_return_amount]
  end

  def current_value
    shares * stock_current_price
  end

  def current_value_cents
    shares * stock_price_cents
  end

  def self.for_portfolio(portfolio)
    Stock
      .joins(:portfolio_stocks)
      .where(portfolio_stocks: { portfolio_id: portfolio.id })
      .group("stocks.id")
      .having("SUM(portfolio_stocks.shares) > 0")
      .select(
        <<~SQL.squish
          stocks.*,
          SUM(portfolio_stocks.shares) AS total_shares,
          (stocks.price_cents / 100.0) * SUM(portfolio_stocks.shares) -
          SUM(portfolio_stocks.purchase_price * portfolio_stocks.shares) AS aggregated_change_amount,
          (stocks.price_cents / 100.0) * SUM(portfolio_stocks.shares) AS aggregated_total_return
        SQL
      )
      .map { |result| build_position(result, portfolio) }
  end

  def self.build_position(result, portfolio)
    new(
      stock: result,
      shares: result.total_shares,
      portfolio: portfolio,
      financial_data: {
        change_amount: result.aggregated_change_amount,
        total_return_amount: result.aggregated_total_return
      }
    )
  end

  private_class_method :build_position
end
