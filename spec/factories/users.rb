FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email(name: "#{Faker::Name.first_name}") }
    username { Faker::Internet.username(specifier: "#{first_name}") }
    active { true }
    password { "test123" }
    password_confirmation {  "test123" }
  end
end