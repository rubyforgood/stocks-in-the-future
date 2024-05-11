class School < ApplicationRecord
  has_many :school_years, dependent: :destroy
  has_many :years, through: :school_years
  has_many :classrooms, dependent: :destroy
end
