class Week < ApplicationRecord
  belongs_to :academic_year

  validates :academic_year_id, presence: true
  validates :start_date, presence: true
end
