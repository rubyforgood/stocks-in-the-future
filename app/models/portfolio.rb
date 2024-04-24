class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :portfolio_transactions
  has_many :portfolio_stocks
end
