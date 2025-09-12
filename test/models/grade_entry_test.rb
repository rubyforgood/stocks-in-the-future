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
end
