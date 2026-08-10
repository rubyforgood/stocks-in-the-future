# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  delegate :username, to: :user

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

  # **Derived where the quarter says how many days there were, stored where it does not.**
  #
  # A teacher typed the day count and then answered a second control claiming every day was attended, and
  # nothing reconciled them: the seeds contain an entry flagged perfect with `attendance_days` nil, paid
  # the bonus, and another treating 3 days as perfect. Two fields for one fact, with the money following
  # the one nobody could check.
  #
  # `quarters.school_days` is the denominator that was missing. Where it is set the answer is arithmetic
  # and the teacher is not asked; where it is nil - every quarter until the figure is collected - the
  # stored flag still decides, so nothing that has already been graded changes meaning and no grade book
  # stops working while the number is being filled in.
  def perfect_attendance?
    # **A completed grade book keeps the answer it was paid on.**
    #
    # Its inputs are locked - the fields are disabled and the controller refuses the write - so before
    # this derivation existed, the figures a completed book displayed always equalled the deposits in the
    # ledger. `quarters.school_days` lives *outside* the grade book and an admin can change it at any
    # time, so without this an edit to a school year would silently move the earnings shown on books paid
    # months ago while the money stayed where it was. A page disagreeing with the ledger is worse than
    # either number being wrong on its own.
    #
    # `is_perfect_attendance` is what was paid on, because `DistributeEarnings` freezes the derived
    # answer into it inside the same transaction that deposits.
    return is_perfect_attendance if grade_book&.completed?

    days = school_days
    return is_perfect_attendance if days.blank?

    attendance_days.present? && attendance_days >= days
  end

  # Whether this entry's answer is arithmetic or a teacher's. The grade book asks, so it can show a
  # figure instead of a control.
  def perfect_attendance_derived?
    school_days.present?
  end

  def school_days
    grade_book&.quarter&.school_days
  end

  def attendance_perfect_earnings
    return 0 unless perfect_attendance?

    EARNINGS_FOR_PERFECT_ATTENDANCE
  end

  def math_improvement_earnings(previous_entry)
    return 0 unless previous_entry
    return 0 if math_grade.blank? || previous_entry.math_grade.blank?

    improved_grade?(math_grade, previous_entry.math_grade) ? EARNINGS_FOR_IMPROVED_GRADE : 0
  end

  def reading_improvement_earnings(previous_entry)
    return 0 unless previous_entry
    return 0 if reading_grade.blank? || previous_entry.reading_grade.blank?

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
