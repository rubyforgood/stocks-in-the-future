# frozen_string_literal: true

FactoryBot.define do
  factory :portfolio_stock do
    association :portfolio
    association :stock
    shares { 10.0 }
    purchase_price { 100.0 }
  end
end
