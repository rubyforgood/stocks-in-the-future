FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.username }
    password { Faker::Internet.password }
    password_confirmation { password }
    active { true }
    role { Faker::Number.between(from: 0, to: 3) }
  end
end
