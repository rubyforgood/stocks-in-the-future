# frozen_string_literal: true

# test/models/grade_entry_test.rb
require "test_helper"

class GradeEntryTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:grade_entry).validate!
  end

  test "math_grade, reading_grade, and perfect_weeks accept any string or nil" do
    entry = build(
      :grade_entry,
      math_grade: "A+",
      reading_grade: "B-",
      perfect_weeks: 12
    )
    assert entry.valid?

    entry.math_grade = nil
    entry.reading_grade = nil
    entry.perfect_weeks = nil
    assert entry.valid?
  end
end
