class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms
end
