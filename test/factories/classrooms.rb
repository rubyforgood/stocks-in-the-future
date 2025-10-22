# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    sequence(:name) { |n| "Classroom #{n}" }
    grade { Classroom::GRADE_RANGE.sample }
    trading_enabled { true }
    association :school_year
  end
end
