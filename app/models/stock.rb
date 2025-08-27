# frozen_string_literal: true

class Stock < ApplicationRecord
  SYMBOLS = %w[KO SNE TWX DIS SIRI F EA FB UA LUV GPS].freeze

  has_many :portfolio_stocks, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  validates :ticker, presence: true

  def current_price
    price_cents / 100.0
  end
end
