# frozen_string_literal: true

class PortfolioStock < ApplicationRecord
  belongs_to :portfolio
  belongs_to :stock

  # Calculate the earnings of a single share of the stock
  def calculate_earnings
    # based on purchase price
  end
end
