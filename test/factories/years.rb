FactoryBot.define do
  factory :year do
    sequence(:name) { |n| (2000 + n).to_s }
  end
end
