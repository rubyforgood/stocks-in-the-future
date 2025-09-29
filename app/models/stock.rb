# frozen_string_literal: true

class Stock < ApplicationRecord
  has_many :portfolio_stocks, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  validates :ticker, presence: true

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def current_price
    price_cents.to_f / 100
  end

  def yesterday_price
    return current_price if yesterday_price_cents.nil?

    yesterday_price_cents.to_f / 100
  end
end
