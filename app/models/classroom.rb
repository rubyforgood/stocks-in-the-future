class Classroom < ApplicationRecord
  belongs_to :year
  belongs_to :school
  has_many :users
end
