# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    stock
    shares { 1 }
    user { create(:student) }
    action { :sell } # Default to sell to avoid validation issues
  end

  trait :pending do
    status { :pending }
  end

  trait :completed do
    status { :completed }
  end

  trait :canceled do
    status { :canceled }
  end

  trait :buy do
    action { :buy }
  end

  trait :sell do
    action { :sell }
  end

  trait :with_sufficient_funds do
    after(:create) do |order|
      order.user.portfolio.portfolio_transactions.create!(
        amount_cents: 100_000, # $1000 - plenty for testing
        transaction_type: :deposit
      )
    end
  end

  trait :with_sufficient_shares do
    after(:create) do |order|
      create(
        :portfolio_stock,
        portfolio: order.user.portfolio,
        stock: order.stock,
        shares: 100, # Plenty of shares for testing
        purchase_price: order.stock.price_cents
      )
    end
  end
end
