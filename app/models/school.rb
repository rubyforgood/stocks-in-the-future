class School < ApplicationRecord
  has_many :classrooms, dependent: :destroy
  has_many :school_years, dependent: :destroy
  has_many :years, through: :school_years
end
