FactoryBot.define do
  factory :classroom do
    school
    year
    name { "Ms. Smith" }
  end

  factory :school do
    name { "Middle School" }
  end

  factory :school_year do
    school
    year
  end

  factory :year do
    year { 2020 }
  end
end
