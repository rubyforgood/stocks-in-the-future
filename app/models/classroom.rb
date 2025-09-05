# frozen_string_literal: true

class Classroom < ApplicationRecord
  belongs_to :school_year
  has_one :school, through: :school_year
  has_one :year, through: :school_year

  has_many :users, dependent: :nullify
  has_many :teacher_classrooms, dependent: :destroy
  has_many :teachers, through: :teacher_classrooms
  has_many :students, class_name: "Student", dependent: :nullify
  has_many :grade_books, dependent: :nullify

  validates :name, presence: true
end
