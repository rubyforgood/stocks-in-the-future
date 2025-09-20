# frozen_string_literal: true

class PortfolioSnapshot < ApplicationRecord
  belongs_to :portfolio

  validates :date, presence: true
  validates :worth_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :portfolio_id, uniqueness: { scope: :date }

  def current_worth
    worth_cents / 100.0
  end
end
