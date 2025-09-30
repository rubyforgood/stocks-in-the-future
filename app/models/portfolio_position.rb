# frozen_string_literal: true

class PortfolioPosition
  attr_reader :stock, :shares, :portfolio, :change_amount, :total_return_amount

  delegate :current_price, :price_cents, :ticker, :yesterday_price, to: :stock, prefix: :stock

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

  def stock_previous_close
    stock_yesterday_price
  end

  def self.for_portfolio(portfolio)
    portfolio
      .portfolio_stocks
      .joins(:stock)
      .group("stocks.id")
      .having("SUM(portfolio_stocks.shares) > 0")
      .select(
        "stocks.*,
         SUM(portfolio_stocks.shares) as total_shares,
         SUM((stocks.price_cents/100.0 - portfolio_stocks.purchase_price) * portfolio_stocks.shares)
           as aggregated_change_amount,
         SUM((stocks.price_cents/100.0) * portfolio_stocks.shares) as aggregated_total_return"
      )
      .map { |result| build_position(result, portfolio) }
  end

  def self.build_position(result, portfolio)
    new(
      stock: Stock.find(result.id),
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
