class PortfolioStock < ApplicationRecord
  belongs_to :portfolio
  belongs_to :stock

  # Calculate the dividend yield of the a stock in the portfolio
  def calculate_dividend_yield
    # based on current price and divident payout (will be in company info)
  end

  # Calculate the earnings of a single share of the stock
  def calculate_earnings
    # based on purchase price
  end
end
