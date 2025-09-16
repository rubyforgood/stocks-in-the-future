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

  test "#finalizable?" do
    entry = build(:grade_entry, math_grade: nil, reading_grade: nil, attendance_days: nil)
    assert_not entry.finalizable?

    entry.math_grade = "A"
    assert_not entry.finalizable?

    entry.reading_grade = "B"
    assert_not entry.finalizable?

    entry.attendance_days = 30
    assert entry.finalizable?
  end

  test "#earnings_for_attendance is 20 cents per day" do
    entry = build(:grade_entry, attendance_days: 0)
    assert_equal 0, entry.earnings_for_attendance

    entry.attendance_days = 5
    assert_equal 100, entry.earnings_for_attendance

    entry.attendance_days = 12
    assert_equal 240, entry.earnings_for_attendance
  end

  test "#earnings_for_attendance includes $1 bonus if perfect attendance" do
    entry = build(:grade_entry, attendance_days: 5, is_perfect_attendance: true)
    assert_equal 2_00, entry.earnings_for_attendance

    entry.is_perfect_attendance = false
    assert_equal 1_00, entry.earnings_for_attendance
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

  test "#total_earnings sums attendance, reading, and math earnings" do
    entry = build(:grade_entry, math_grade: "A", reading_grade: "B", attendance_days: 9)
    assert_equal 3_00 + 2_00 + (9 * 20), entry.total_earnings
  end

  test "#improvement_earnings is 0 if no improvement from the previous entry" do
    previous_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")
    entry = build(:grade_entry, math_grade: "C", reading_grade: "D")

    assert_equal 0, entry.improvement_earnings(previous_entry)
  end

  test "#improvement_earnings is $2 if math grade has improved" do
    previous_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")
    improved_grades = %w[B B+ A- A A+]
    improved_grades.each do |grade|
      entry = build(:grade_entry, math_grade: grade, reading_grade: "C")
      assert_equal 2_00, entry.improvement_earnings(previous_entry), "Grade #{grade} should yield improvement earnings"
    end
  end

  test "#improvement_earnings is $2 if reading grade has improved" do
    previous_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")
    improved_grades = %w[B B+ A- A A+]
    improved_grades.each do |grade|
      entry = build(:grade_entry, math_grade: "C", reading_grade: grade)
      assert_equal 2_00, entry.improvement_earnings(previous_entry), "Grade #{grade} should yield improvement earnings"
    end
  end

  test "#improvement_earnings is $4 if both grades have improved" do
    previous_entry = build(:grade_entry, math_grade: "C", reading_grade: "C")

    entry = build(:grade_entry, math_grade: "B", reading_grade: "A")

    assert_equal 4_00, entry.improvement_earnings(previous_entry)
  end
end
