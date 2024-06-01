class Year < ApplicationRecord
  has_many :school_years, dependent: :nullify
  has_many :schools, through: :school_years

  validates :year, presence: true, uniqueness: true
end
