FactoryBot.define do
  factory :school do
    name { Faker::Educator.secondary_school }
    academic_year
  end
end
