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

  test "#award_for_attendance is 20 cents per day" do
    entry = build(:grade_entry, attendance_days: 0)
    assert_equal 0, entry.award_for_attendance

    entry.attendance_days = 5
    assert_equal 100, entry.award_for_attendance

    entry.attendance_days = 12
    assert_equal 240, entry.award_for_attendance
  end

  test "#award_for_reading grade is $2 for B, $3 for an A" do
    entry = build(:grade_entry, reading_grade: nil)

    ["F", "D", "C-", "C", "C+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 0, entry.award_for_reading
    end

    ["B-", "B", "B+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 2_00, entry.award_for_reading
    end

    ["A-", "A", "A+"].each do |grade|
      entry.reading_grade = grade
      assert_equal 3_00, entry.award_for_reading
    end
  end

  test "#award_for_math grade is $2 for B, $3 for an A" do
    entry = build(:grade_entry, math_grade: nil)

    ["F", "D", "C-", "C", "C+"].each do |grade|
      entry.math_grade = grade
      assert_equal 0, entry.award_for_math
    end

    ["B-", "B", "B+"].each do |grade|
      entry.math_grade = grade
      assert_equal 2_00, entry.award_for_math
    end

    ["A-", "A", "A+"].each do |grade|
      entry.math_grade = grade
      assert_equal 3_00, entry.award_for_math
    end
  end

  test "#total_award sums attendance, reading, and math awards" do
    entry = build(:grade_entry, math_grade: "A", reading_grade: "B", attendance_days: 9)
    assert_equal 3_00 + 2_00 + (9 * 20), entry.total_award
  end
end
