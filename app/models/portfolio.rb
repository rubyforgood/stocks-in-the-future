class Portfolio < ApplicationRecord
  belongs_to :user, -> { where(type: 'Student') }
  has_many :portfolio_transactions
  has_many :portfolio_stocks
  has_many :stocks, through: :portfolio_stocks  

  # a User (specifically student) can buy a certain amount of stock 
  def buy_stock(ticker:, quantity:)
    stock = Stock.find_by(ticker: ticker)
    stocks << stock
  end

  # a User (specifically student) can sell a certain amount of stock 
  def sell_stock(ticker:, quantity:)
    # Logic for selling stock
  end

  # a User (usually teacher) can deposit money
  def deposit_money(amount:)
    # Logic for depositing 
  end

  # a User (usually teacher) can withdraw money
  def withdraw_money(amount:)
    # Logic for withdrawing
  end

  # Calculates the total value of the portfolio, including both cash and stock holdings.
  def calculate_value
    # Logic for calculating portfolio value
  end

  # Calculates the overall profit or loss of the portfolio based on the current value compared to the initial investment.
  def calculate_standing
    # Logic for calculating stock value
  end

  # A Student can view statements within a certain window of time
  def generate_statement(start_date:, end_date:)
    # Logic for generating statement
  end

  # Generate a list of stocks that this portfolio owns
  def list_stocks
    # Logic for listing stocks
  end

  # Portfolios can be closed by a teacher or admin -- can no longer have student activity
  def close_portfolio
    # Logic for closing portfolio 
  end
end
