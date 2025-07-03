# frozen_string_literal: true

# test/models/grade_entry_test.rb
require "test_helper"

class GradeEntryTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:grade_entry).validate!
  end

  test "valid when days_missed is zero or positive" do
    entry = build(:grade_entry, days_missed: 3)
    assert entry.valid?
  end

  test "invalid when days_missed is negative" do
    entry = build(:grade_entry, days_missed: -1)
    assert_not entry.valid?
    assert_includes entry.errors[:days_missed], "must be greater than or equal to 0"
  end

  test "math_grade and reading_grade accept any string or nil" do
    entry = build(
      :grade_entry,
      math_grade: "A+",
      reading_grade: "B-",
      days_missed: 0
    )
    assert entry.valid?

    entry.math_grade = nil
    entry.reading_grade = nil
    assert entry.valid?
  end
end
