# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment do
    association :student
    association :classroom
  end
end
