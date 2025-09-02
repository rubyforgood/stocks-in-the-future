# frozen_string_literal: true

class PortfolioPosition
  delegate :id, :ticker, :company_name, :price_cents, :current_price, to: :stock, prefix: :stock

  def initialize(portfolio:, stock:, total_shares: nil, avg_purchase_price: nil)
    @portfolio = portfolio
    @stock_or_stock_id = stock
    @precomputed_total_shares = total_shares
    @precomputed_avg_purchase_price = avg_purchase_price
  end

  def stock
    @stock ||= @stock_or_stock_id.is_a?(Stock) ? @stock_or_stock_id : Stock.find(@stock_or_stock_id)
  end

  def total_shares
    @precomputed_total_shares ||
      @portfolio.portfolio_stocks.where(stock: @stock_or_stock_id).sum(:shares) ||
      0
  end

  def avg_purchase_price
    @precomputed_avg_purchase_price ||
      @portfolio.portfolio_stocks.where(stock: @stock_or_stock_id).average(:purchase_price) ||
      0
  end

  def avg_purchase_price_dollars
    avg_purchase_price / 100.0
  end


  def to_s
    "#{stock_company_name} (#{stock_ticker}): #{total_shares} shares"
  end
end
