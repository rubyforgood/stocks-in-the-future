# frozen_string_literal: true

FactoryBot.define do
  factory :grade_book do
    association :quarter
    association :classroom

    status { "draft" }
  end
end
