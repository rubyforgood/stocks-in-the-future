# frozen_string_literal: true

# test/factories/quarters.rb
# SchoolYear auto-creates 4 quarters via after_create, so create(:quarter) finds
# the existing quarter rather than inserting a new one (which would violate the
# uniqueness constraint on number scoped to school_year).
FactoryBot.define do
  factory :quarter do
    association :school_year
    number { 1 }
    name { "Quarter #{number}" }

    to_create do |instance|
      instance.id = instance.school_year.quarters.find_by!(number: instance.number).id
      instance.reload
    end
  end
end
