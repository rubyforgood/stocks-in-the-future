# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    stock
    user { create(:admin) }
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
end
