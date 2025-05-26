class Year < ApplicationRecord
  has_many :school_years, dependent: :destroy
  has_many :schools, through: :school_years
  has_many :classrooms, through: :school_years

  validates :name, presence: true, uniqueness: true
end
