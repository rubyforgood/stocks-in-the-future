class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :school_week

  validates :user, presence: true
  validates :school_week, presence: true
end
