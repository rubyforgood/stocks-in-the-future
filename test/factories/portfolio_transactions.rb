# frozen_string_literal: true

FactoryBot.define do
  factory :portfolio_transaction do
    portfolio
    amount_cents { 1_000 }
  end

  trait :debit do
    transaction_type { :debit }
  end

  trait :credit do
    transaction_type { :credit }
  end
end
