# frozen_string_literal: true

class Grade < ApplicationRecord
  has_many :classroom_grades, dependent: :restrict_with_error
  has_many :classrooms, through: :classroom_grades

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :level, presence: true, uniqueness: true
end
