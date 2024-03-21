class Portfolio < ApplicationRecord
  belongs_to :user, -> { where(type: 'Student') }
  has_many :portfolio_transactions
  has_many :portfolio_stocks
  has_many :stocks, through: :portfolio_stocks  
end
