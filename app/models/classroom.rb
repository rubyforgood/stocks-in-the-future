# frozen_string_literal: true

class Classroom < ApplicationRecord
  MIN_GRADE = 5
  MAX_GRADE = 12
  GRADE_RANGE = (MIN_GRADE..MAX_GRADE).to_a.freeze

  belongs_to :school_year
  has_one :school, through: :school_year
  has_one :year, through: :school_year

  has_many :users, dependent: :nullify
  has_many :teacher_classrooms, dependent: :destroy
  has_many :teachers, through: :teacher_classrooms
  has_many :students, -> { kept }, class_name: "Student", inverse_of: :classroom, dependent: :nullify
  has_many :classroom_grades, dependent: :destroy
  has_many :grades, through: :classroom_grades
  has_many :grade_books, dependent: :nullify

  validates :name, presence: true

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def grade_display
    grade&.ordinalize
  end

  def to_s
    if grade_display.present?
      "#{name} (#{grade_display})"
    else
      name
    end
  end
end
