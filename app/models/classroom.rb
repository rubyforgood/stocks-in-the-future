class Classroom < ApplicationRecord
  belongs_to :school_year

  has_many :users, dependent: :destroy
end
