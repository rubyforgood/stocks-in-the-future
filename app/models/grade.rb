# frozen_string_literal: true

class Grade < ApplicationRecord
  has_many :classroom_grades, dependent: :destroy
  has_many :classrooms, through: :classroom_grades

  validates :name, presence: true
  validates :level, presence: true
end
