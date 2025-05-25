FactoryBot.define do
  factory :user do
    classroom
    password { "Passw0rd" }
    sequence(:username) { |n| "test_user_#{n}" }
    sequence(:email) { |n| "test_user_#{n}@example.com" }
  end
end
