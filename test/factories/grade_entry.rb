# frozen_string_literal: true

# test/factories/grade_entries.rb
FactoryBot.define do
  factory :grade_entry do
    association :grade_book
    association :user, factory: :student

    math_grade    { nil }
    reading_grade { nil }
    days_missed   { 0 }
  end
end
