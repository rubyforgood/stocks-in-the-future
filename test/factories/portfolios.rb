# frozen_string_literal: true

FactoryBot.define do
  factory :portfolio do
    user { create(:student) }
  end
end
