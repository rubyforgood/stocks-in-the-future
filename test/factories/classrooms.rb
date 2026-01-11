# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    sequence(:name) { |n| "Classroom #{n}" }
    trading_enabled { false }
    association :school_year

    # Default: create one grade (required by validation)
    after(:create) do |classroom|
      create(:classroom_grade, classroom: classroom)
    end

    trait :with_trading do
      trading_enabled { true }
    end

    # Default: one random grade (single-grade behavior)
    trait :with_grade do
      after(:create) do |classroom|
        create(:classroom_grade, classroom: classroom)
      end
    end

    trait :with_grades do
      transient do
        grades_count { 3 }
      end

      after(:create) do |classroom, evaluator|
        create_list(:classroom_grade, evaluator.grades_count, classroom: classroom)
      end
    end
  end
end
