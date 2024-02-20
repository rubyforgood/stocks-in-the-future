class Year < ApplicationRecord
  has_many :school_years
  has_many :schools, through: :school_years

  validates :year, presence: true, uniqueness: true
end
