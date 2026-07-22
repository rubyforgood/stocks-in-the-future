# frozen_string_literal: true

FactoryBot.define do
  factory :grade_book do
    quarter { create(:school_year).quarters.first }
    association :classroom

    status { "draft" }
  end
end
