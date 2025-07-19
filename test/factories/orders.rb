# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    stock
    shares { 1 }
    user { create(:student) }
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
    transaction_type { "buy" }
  end

  trait :sell do
    transaction_type { "sell" }
  end
end
