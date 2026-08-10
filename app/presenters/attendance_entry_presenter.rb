# frozen_string_literal: true

class AttendanceEntryPresenter < BasePresenter
  def self.for_student(student)
    GradeEntry.where(user: student)
      .joins(grade_book: { quarter: { school_year: :year } })
      .includes(grade_book: { quarter: { school_year: :year } })
      .order("years.name ASC, quarters.number ASC")
      .map { |entry| new(entry) }
  end

  def year_name
    object.grade_book.quarter.school_year.year.name
  end

  def quarter_name
    "Q#{object.grade_book.quarter.number}"
  end

  def attendance_days_display
    object.attendance_days || "—"
  end

  def perfect_attendance?
    object.is_perfect_attendance
  end
end
