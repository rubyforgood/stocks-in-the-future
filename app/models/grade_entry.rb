# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  PER_DAY_ATTENDANCE_AWARD = 20
  AWARD_FOR_A_GRADE = 3_00
  AWARD_FOR_B_GRADE = 2_00
  AWARD_FOR_IMPROVED_GRADE = 2_00
  AWARD_FOR_PERFECT_ATTENDANCE = 1_00

  GRADE_OPTIONS = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"].freeze

  def finalizable? = math_grade.present? && reading_grade.present? && attendance_days.present?

  def award_for_attendance
    return 0 unless attendance_days.present? && attendance_days.nonzero?

    value = (attendance_days || 0) * PER_DAY_ATTENDANCE_AWARD
    value += AWARD_FOR_PERFECT_ATTENDANCE if is_perfect_attendance
    value
  end

  def award_for_reading = grade_based_award(reading_grade)

  def award_for_math = grade_based_award(math_grade)

  def total_award = award_for_attendance + award_for_reading + award_for_math

  def improvement_award(previous_entry)
    award = 0
    award += AWARD_FOR_IMPROVED_GRADE if improved_grade?(math_grade, previous_entry.math_grade)
    award += AWARD_FOR_IMPROVED_GRADE if improved_grade?(reading_grade, previous_entry.reading_grade)
    award
  end

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

  def improved_grade?(current_grade,
                      previous_grade)
    GRADE_OPTIONS.index(current_grade) < GRADE_OPTIONS.index(previous_grade)
  end
end
