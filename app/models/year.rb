class Year < ApplicationRecord
  has_many :classrooms, dependent: :destroy
  has_many :school_years, dependent: :destroy
  has_many :schools, through: :school_years

  validates :year, presence: true, uniqueness: true
end
