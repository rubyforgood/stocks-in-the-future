FactoryBot.define do
  factory :portfolio do
    user { create(:student) }
  end
end
