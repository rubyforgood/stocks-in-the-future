FactoryBot.define do
  factory :cohort do
    name { "#{Faker::Educator.secondary_school} 2023" }
    association :school
    association :academic_year
    grade_level { [6, 7, 8].sample }
    association :teacher, factory: :user
    active { true }
  end
end
