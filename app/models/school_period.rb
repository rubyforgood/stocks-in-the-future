class SchoolPeriod < ApplicationRecord
  belongs_to :cohort
  belongs_to :school

  validates :cohort_id, presence: true
  validates :school_id, presence: true
end
