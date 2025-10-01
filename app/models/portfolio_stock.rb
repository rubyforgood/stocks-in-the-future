# frozen_string_literal: true

# NOTE: for calculations, use `PortfolioPosition` as an aggregate.
class PortfolioStock < ApplicationRecord
  belongs_to :portfolio
  belongs_to :stock
end
