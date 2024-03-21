class Stock < ApplicationRecord
  belongs_to :company
  has_many :portfolio_stocks
  belongs_to :portfolios, through: :portfolio_stocks
end
