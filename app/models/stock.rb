# frozen_string_literal: true

class Stock < ApplicationRecord
  SYMBOLS = %w[KO SNE TWX DIS SIRI F EA FB UA LUV GPS].freeze

  has_many :portfolio_stocks
  has_many :orders

  validates :ticker, presence: true

  def current_price
    price_cents / 100.0
  end
end
