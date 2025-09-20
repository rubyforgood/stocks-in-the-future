# frozen_string_literal: true

FactoryBot.define do
  factory :portfolio_snapshot do
    portfolio { create(:portfolio) }
    date { Date.current }
    worth_cents { 50_000 }
  end
end
