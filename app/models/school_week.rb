class SchoolWeek < ApplicationRecord
  belongs_to :school_period

  has_many :attendances

  validates :school_period_id, presence: true
end
