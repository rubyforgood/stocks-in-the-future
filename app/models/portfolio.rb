class Portfolio < ApplicationRecord
  belongs_to :user

  has_many :portfolio_transactions, dependent: :destroy
  has_many :portfolio_stocks, dependent: :destroy
  has_many :stocks, through: :portfolio_stocks

  def cash_balance
    portfolio_transactions.sum(:amount_cents) / 100.0
  end
end
