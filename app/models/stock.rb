class Stock < ApplicationRecord
  SYMBOLS = %w[KO SNE TWX DIS SIRI F EA FB UA LUV GPS].freeze

  has_many :portfolio_stocks
  has_many :orders
end
