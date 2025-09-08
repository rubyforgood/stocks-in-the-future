# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    sequence(:name) { |n| "Classroom #{n}" }
    sequence(:grade) { |n| "#{n}th" }
    sequence(:grade_numeric) { |n| n }
    association :school_year
  end
end
