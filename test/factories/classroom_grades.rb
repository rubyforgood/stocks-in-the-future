# frozen_string_literal: true

FactoryBot.define do
  factory :classroom_grade do
    association :classroom
    association :grade
  end
end
