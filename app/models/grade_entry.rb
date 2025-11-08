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

  def earnings_for_attendance
    return 0 if attendance_days.blank?

    attendance_days * EARNINGS_PER_DAY_ATTENDANCE
  end

  def earnings_for_math
    grade_based_earnings(math_grade)
  end

  def earnings_for_reading
    grade_based_earnings(reading_grade)
  end

  def attendance_perfect_earnings
    return 0 unless is_perfect_attendance

    EARNINGS_FOR_PERFECT_ATTENDANCE
  end

  def math_improvement_earnings(previous_entry)
    return 0 unless previous_entry
    return 0 if math_grade.nil? || previous_entry.math_grade.nil?

    improved_grade?(math_grade, previous_entry.math_grade) ? EARNINGS_FOR_IMPROVED_GRADE : 0
  end

  def reading_improvement_earnings(previous_entry)
    return 0 unless previous_entry
    return 0 if reading_grade.nil? || previous_entry.reading_grade.nil?

    improved_grade?(reading_grade, previous_entry.reading_grade) ? EARNINGS_FOR_IMPROVED_GRADE : 0
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
