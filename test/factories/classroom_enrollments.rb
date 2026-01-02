# frozen_string_literal: true

FactoryBot.define do
  factory :classroom_enrollment do
    student { association :student }
    classroom { association :classroom }
    enrolled_at { Time.current }
    unenrolled_at { nil }
    primary { false }

    trait :current do
      unenrolled_at { nil }
    end

    trait :historical do
      enrolled_at { 1.year.ago }
      unenrolled_at { 6.months.ago }
    end

    trait :primary do
      primary { true }
    end
  end
end
