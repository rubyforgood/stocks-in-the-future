# frozen_string_literal: true

FactoryBot.define do
  factory :grade do
    sequence(:level) { |n| n }
    sequence(:name)  { |n| "Grade #{n}" }
  end
end
