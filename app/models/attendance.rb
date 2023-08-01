class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :school_week

  validates :user, presence: true
  validates :school_week, presence: true
  validates :school_period_id, presence: true, numericality: {only_integer: true}
  validates :verified, inclusion: {in: [true, false]}
  validates :attended, inclusion: {in: [true, false]}
  validates :quarter_bonus, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1}
end
