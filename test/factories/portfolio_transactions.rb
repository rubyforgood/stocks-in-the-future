FactoryBot.define do
  factory :portfolio_transaction do
    portfolio
    amount_cents { 1_000 }
  end
end
