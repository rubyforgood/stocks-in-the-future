class School < ApplicationRecord
  belongs_to :academic_year

  has_many :cohorts
end
