FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email(name: first_name.to_s) }
    username { Faker::Internet.username(specifier: first_name.to_s) }
    active { true }
    password { "test123" }
    password_confirmation { "test123" }
    role { Faker::Number.between(from: 0, to: 3) }
  end
end
