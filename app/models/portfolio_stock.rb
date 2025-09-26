# frozen_string_literal: true

class PortfolioStock < ApplicationRecord
  belongs_to :portfolio
  belongs_to :stock

  def change_amount
    current_price = stock.current_price
    (current_price - purchase_price) * shares
  end

  def total_return_amount
    stock.current_price * shares
  end

  # Calculate the earnings of a single share of the stock
  def calculate_earnings
    # based on purchase price
  end
end
