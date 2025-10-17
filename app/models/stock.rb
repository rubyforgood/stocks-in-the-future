# frozen_string_literal: true

class Stock < ApplicationRecord
  has_many :portfolio_stocks, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  validates :ticker, presence: true
  validates(
    :company_website,
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      allow_blank: true
    }
  )

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def current_price
    price_cents.to_f / 100
  end

  def yesterday_price
    return current_price if yesterday_price_cents.nil?

    yesterday_price_cents.to_f / 100
  end

  def percentage_change
    return 0.0 if yesterday_price_cents.nil? || yesterday_price_cents.zero?

    ((current_price - yesterday_price) / yesterday_price) * 100
  end

  def percentage_change_formatted
    return "0.00%" if percentage_change.zero?

    formatted = format("%.2f%%", percentage_change.abs)
    percentage_change.positive? ? "+#{formatted}" : "-#{formatted}"
  end
end
