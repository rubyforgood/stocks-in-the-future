# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    stock
    user { create(:admin) }
  end
end
