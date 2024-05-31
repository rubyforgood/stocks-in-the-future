class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :portfolio_transactions
  has_many :portfolio_stocks

  def cash_balance
    portfolio_transactions.sum(:amount)
  end

  # a User (specifically student) can buy a certain amount of stock
  def buy_stock(ticker, shares)
    stock = Stock.find_by(ticker:)

    # calculate the cost, and adjust the portfolio's cash balance -- protfolio_transactions
    # cost = stock.price * shares
    # if self.cash_balance >= cost
    #   transaction = self.portfolio_transactions.create(
    #     stock: stock,
    #     shares: shares,
    #     transaction_type: :buy,
    #     amount: -cost
    #   )
    # self.update(cash_balance: self.cash_balance - cost) if transaction.persisted?

    portfolio_stocks.create(stock:, shares:)
  end

  # a User (specifically student) can sell a certain amount of stock
  def sell_stock(ticker:, shares:)
    stock = Stock.find_by(ticker:)
    portfolio_stock = portfolio_stocks.find_by(stock_id: stock.id)
    return unless portfolio_stock.present? # the stock we're trying to sell doesn't exist, return

    # update cash balance with portfolio_transactions

    # decrement the number of shares, or sell all
    return if portfolio_stock.shares > shares

    # error, can't sell more than you have

    portfolio_stock.update(shares: portfolio_stock.shares - shares)
    portfolio_stock.destroy if portfolio_stock.shares == 0
  end

  # a User (usually teacher) can deposit money
  def deposit_money(amount:)
    # Logic for depositing -- portfolio_transactions
  end

  # a User (usually teacher) can withdraw money
  def withdraw_money(amount:)
    # Logic for withdrawing -- portfolio_transactions
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
    # Logic for generating statement -- portfolio_transactions
  end

  # Generate a list of stocks that this portfolio owns
  def list_stocks
    # Logic for listing stocks -- portfolio_stocks
  end

  # Portfolios can be closed by a teacher or admin -- can no longer have student activity
  def close_portfolio
    # Logic for closing portfolio
  end

  def stocks
    stock_ids = portfolio_stocks.pluck(:stock_id)
    Stock.where(id: stock_ids)
  end
end
