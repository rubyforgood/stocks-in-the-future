# frozen_string_literal: true

# test/factories/school_years.rb
FactoryBot.define do
  factory :school_year do
    association :school
    association :year
  end
end
