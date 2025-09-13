# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  EARNINGS_PER_DAY_ATTENDANCE = 20
  EARNINGS_FOR_A_GRADE = 3_00
  EARNINGS_FOR_B_GRADE = 2_00
  EARNINGS_FOR_IMPROVED_GRADE = 2_00
  EARNINGS_FOR_PERFECT_ATTENDANCE = 1_00

  GRADE_OPTIONS = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"].freeze

  def finalizable? = math_grade.present? && reading_grade.present? && attendance_days.present?

  def earnings_for_attendance
    return 0 unless attendance_days.present? && attendance_days.nonzero?

    value = (attendance_days || 0) * EARNINGS_PER_DAY_ATTENDANCE
    value += EARNINGS_FOR_PERFECT_ATTENDANCE if is_perfect_attendance
    value
  end

  def earnings_for_reading = grade_based_earnings(reading_grade)

  def earnings_for_math = grade_based_earnings(math_grade)

  def total_earnings = earnings_for_attendance + earnings_for_reading + earnings_for_math

  def improvement_earnings(previous_entry)
    earnings = 0
    earnings += EARNINGS_FOR_IMPROVED_GRADE if improved_grade?(math_grade, previous_entry.math_grade)
    earnings += EARNINGS_FOR_IMPROVED_GRADE if improved_grade?(reading_grade, previous_entry.reading_grade)
    earnings
  end

  private

  def grade_based_earnings(grade)
    case grade
    when "A+", "A", "A-"
      EARNINGS_FOR_A_GRADE
    when "B+", "B", "B-"
      EARNINGS_FOR_B_GRADE
    else
      0
    end
  end

  def improved_grade?(current_grade,
                      previous_grade)
    GRADE_OPTIONS.index(current_grade) < GRADE_OPTIONS.index(previous_grade)
  end
end
