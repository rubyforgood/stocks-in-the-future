# frozen_string_literal: true

# test/models/grade_entry_test.rb
require "test_helper"

class GradeEntryTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:grade_entry).validate!
  end

  test "math_grade, reading_grade, and attendance_days accept any string or nil" do
    entry = build(
      :grade_entry,
      math_grade: "A+",
      reading_grade: "B-",
      attendance_days: 45
    )
    assert entry.valid?

    entry.math_grade = nil
    entry.reading_grade = nil
    entry.attendance_days = nil
    assert entry.valid?
  end

  test "#earnings_for_attendance is 20 cents per day" do
    entry = build(:grade_entry, attendance_days: 0)
    assert_equal 0, entry.earnings_for_attendance

    entry.attendance_days = 5
    assert_equal 100, entry.earnings_for_attendance

    entry.attendance_days = 12
    assert_equal 240, entry.earnings_for_attendance
  end

  test "#attendance_perfect_earnings returns $1 only for perfect attendance" do
    entry = build(:grade_entry, attendance_days: 5, is_perfect_attendance: true)
    assert_equal 1_00, entry.attendance_perfect_earnings

    entry.is_perfect_attendance = false
    assert_equal 0, entry.attendance_perfect_earnings
  end

  test "#earnings_for_reading grade is $2 for B, $3 for an A" do
    entry = build(:grade_entry, reading_grade: nil)

    ["F", "D", "C-", "C", "C+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 0, entry.earnings_for_reading
    end

    ["B-", "B", "B+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 2_00, entry.earnings_for_reading
    end

    ["A-", "A", "A+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 3_00, entry.earnings_for_reading
    end
  end

  test "#earnings_for_math grade is $2 for B, $3 for an A" do
    entry = build(:grade_entry, math_grade: nil)

    ["F", "D", "C-", "C", "C+"].each do |grade|
      entry.math_grade = grade
      assert_equal 0, entry.earnings_for_math
    end

    ["B-", "B", "B+"].each do |grade|
      entry.math_grade = grade
      assert_equal 2_00, entry.earnings_for_math
    end

    ["A-", "A", "A+"].each do |grade|
      entry.math_grade = grade
      assert_equal 3_00, entry.earnings_for_math
    end
  end

  test "subject improvement earnings returns 0 when no previous entry or no improvement" do
    entry = build(:grade_entry, math_grade: "A", reading_grade: "A")
    assert_equal 0, entry.math_improvement_earnings(nil)
    assert_equal 0, entry.reading_improvement_earnings(nil)

    previous_entry = build(:grade_entry, math_grade: "B", reading_grade: "B")
    worse_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")
    assert_equal 0, worse_entry.math_improvement_earnings(previous_entry)
    assert_equal 0, worse_entry.reading_improvement_earnings(previous_entry)
  end

  test "subject improvement earnings returns $2 when grade has improved" do
    previous_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")
    improved_entry = build(:grade_entry, math_grade: "B", reading_grade: "B")

    assert_equal 2_00, improved_entry.math_improvement_earnings(previous_entry)
    assert_equal 2_00, improved_entry.reading_improvement_earnings(previous_entry)
  end

  # Perfect attendance is derived where the quarter says how many days there were.
  #
  # Money changes with this, so both paths are pinned as literals: the bonus is
  # EARNINGS_FOR_PERFECT_ATTENDANCE and it now follows arithmetic rather than a second answer nobody
  # could check. The seeds contained an entry flagged perfect with attendance_days nil, paid, and another
  # treating 3 days as perfect.
  # The quarter factory's `to_create` swaps in the row `SchoolYear` already made, so attributes passed to
  # it are discarded - `school_days` has to be set afterwards, on the record that actually exists.
  def entry_in_quarter(school_days:, days:, flag:)
    quarter = create(:quarter)
    quarter.update!(school_days:)
    book = create(:grade_book, quarter:)
    create(:grade_entry, grade_book: book, attendance_days: days, is_perfect_attendance: flag)
  end

  test "with a school-day count, attendance is arithmetic and the flag is ignored" do
    entry = entry_in_quarter(school_days: 45, days: 45, flag: false)

    assert_predicate entry, :perfect_attendance?
    assert_equal GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE, entry.attendance_perfect_earnings
  end

  test "a flag claiming perfect attendance against a short count earns nothing" do
    entry = entry_in_quarter(school_days: 45, days: 3, flag: true)

    assert_not_predicate entry, :perfect_attendance?
    assert_equal 0, entry.attendance_perfect_earnings
  end

  test "a flag with no days at all earns nothing once the quarter has a count" do
    entry = entry_in_quarter(school_days: 45, days: nil, flag: true)

    assert_not_predicate entry, :perfect_attendance?
    assert_equal 0, entry.attendance_perfect_earnings
  end

  test "without a school-day count the stored flag still decides, so nothing already graded changes" do
    entry = entry_in_quarter(school_days: nil, days: 3, flag: true)

    assert_predicate entry, :perfect_attendance?
    assert_equal GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE, entry.attendance_perfect_earnings
    assert_not entry.perfect_attendance_derived?
  end

  test "more days than the quarter has still counts as perfect" do
    entry = entry_in_quarter(school_days: 45, days: 46, flag: false)

    assert_predicate entry, :perfect_attendance?
  end
end
