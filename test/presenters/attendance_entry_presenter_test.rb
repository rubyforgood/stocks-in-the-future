# frozen_string_literal: true

require "test_helper"

class AttendanceEntryPresenterTest < ActiveSupport::TestCase
  test "year_name returns the year name from the nested association" do
    entry = create_entry(year_name: "2025", quarter_number: 2)

    assert_equal "2025", AttendanceEntryPresenter.new(entry).year_name
  end

  test "quarter_name formats the quarter number" do
    entry = create_entry(year_name: "2025", quarter_number: 3)

    assert_equal "Q3", AttendanceEntryPresenter.new(entry).quarter_name
  end

  test "attendance_days_display returns the raw value when present" do
    entry = create_entry(year_name: "2025", quarter_number: 1, attendance_days: 42)

    assert_equal 42, AttendanceEntryPresenter.new(entry).attendance_days_display
  end

  test "attendance_days_display returns a dash when nil" do
    entry = create_entry(year_name: "2025", quarter_number: 1, attendance_days: nil)

    assert_equal "—", AttendanceEntryPresenter.new(entry).attendance_days_display
  end

  test "perfect_attendance? reflects the underlying flag" do
    entry = create_entry(year_name: "2025", quarter_number: 1, is_perfect_attendance: true)

    assert_predicate AttendanceEntryPresenter.new(entry), :perfect_attendance?
  end

  test "for_student returns presenters ordered by year then quarter" do
    student = create(:student)
    create_entry(year_name: "2026", quarter_number: 1, user: student)
    create_entry(year_name: "2025", quarter_number: 2, user: student)
    create_entry(year_name: "2025", quarter_number: 1, user: student)

    entries = AttendanceEntryPresenter.for_student(student)

    assert_equal(
      [%w[2025 Q1], %w[2025 Q2], %w[2026 Q1]],
      entries.map { |e| [e.year_name, e.quarter_name] }
    )
  end

  test "for_student scopes to the given student" do
    student = create(:student)
    other_student = create(:student)
    create_entry(year_name: "2025", quarter_number: 1, user: student)
    create_entry(year_name: "2025", quarter_number: 1, user: other_student)

    assert_equal 1, AttendanceEntryPresenter.for_student(student).size
  end

  def create_entry(year_name:, quarter_number:, user: nil, attendance_days: 10, is_perfect_attendance: false)
    user ||= create(:student)
    year = Year.find_or_create_by!(name: year_name)
    school_year = create(:school_year, year: year)
    quarter = create(:quarter, school_year: school_year, number: quarter_number)
    grade_book = create(:grade_book, quarter: quarter, classroom: user.classroom)
    create(
      :grade_entry,
      grade_book: grade_book,
      user: user,
      attendance_days: attendance_days,
      is_perfect_attendance: is_perfect_attendance
    )
  end
end
