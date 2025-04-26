class Classroom < ApplicationRecord
  belongs_to :school
  belongs_to :year

  has_many :users, dependent: :nullify
end
