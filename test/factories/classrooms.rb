# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    sequence(:name) { |n| "Classroom #{n}" }
    grade { Classroom::GRADE_RANGE.sample }
    association :school_year
  end
end
