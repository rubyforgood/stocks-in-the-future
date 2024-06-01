class Stock < ApplicationRecord
  has_many :portfolio_stocks, dependent: :nullify
  has_many :orders, dependent: :nullify

  # Retreive general Stock information
  def stock_information
    # logic to pull stock info from the company
    # put it in a digestable format
  end
end
