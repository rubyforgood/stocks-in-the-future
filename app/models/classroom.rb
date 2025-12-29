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
  validate :has_grade_level

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def grades_display
    values = classroom_grades
             .joins(:grade)
             .pluck("grades.level")
             .uniq
             .sort
    return if values.empty?

    if values.one?
      values.first.ordinalize
    elsif continuous?(values)
      "#{values.first.ordinalize}-#{values.last.ordinalize}"
    else
      values.map(&:ordinalize).join(", ")
    end
  end

  def continuous?(values)
    values.each_cons(2).all? { |a, b| b == a + 1 }
  end

  def to_s
    if grade_display.present?
      "#{name} (#{grade_display})"
    else
      name
    end
  end
end

private

def has_grade_level
  errors.add(:grades, "must have at least one grade") if grades.empty?
end