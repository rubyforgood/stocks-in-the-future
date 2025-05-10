FactoryBot.define do
  factory :year do
    sequence(:year) { |n| 2000 + n }
  end
end
