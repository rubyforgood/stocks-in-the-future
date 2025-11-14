# frozen_string_literal: true

# test/factories/quarters.rb
FactoryBot.define do
  factory :quarter do
    association :school_year
    sequence(:number) { |n| ((n - 1) % 4) + 1 }

    sequence(:name) { |n| "Q#{((n - 1) % 4) + 1} - #{Date.current.year + ((n - 1) / 4)}" }
  end
end
