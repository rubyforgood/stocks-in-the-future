FactoryBot.define do
  factory :year do
    sequence(:name) { |n| "#{200 + n} - #{2000 + n + 1}" }
  end
end
