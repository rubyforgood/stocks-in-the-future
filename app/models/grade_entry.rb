# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  PER_DAY_ATTENDANCE_AWARD = 20
  AWARD_FOR_A_GRADE = 3_00
  AWARD_FOR_B_GRADE = 2_00

  GRADE_OPTIONS = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"].freeze

  def finalizable? = math_grade.present? && reading_grade.present? && attendance_days.present?
  def award_for_attendance = (attendance_days || 0) * PER_DAY_ATTENDANCE_AWARD
  def award_for_reading = grade_based_award(reading_grade)
  def award_for_math = grade_based_award(math_grade)
  def total_award = award_for_attendance + award_for_reading + award_for_math

  private

  def grade_based_award(grade)
    case grade
    when "A+", "A", "A-"
      AWARD_FOR_A_GRADE
    when "B+", "B", "B-"
      AWARD_FOR_B_GRADE
    else
      0
    end
  end
end
