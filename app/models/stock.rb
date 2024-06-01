class Stock < ApplicationRecord
  has_many :portfolio_stocks, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  # Retreive general Stock information
  def stock_information
    # logic to pull stock info from the company
    # put it in a digestable format
  end
end
