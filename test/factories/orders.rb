FactoryBot.define do
  factory :order do
    stock
    user { create(:admin) }
  end
end
