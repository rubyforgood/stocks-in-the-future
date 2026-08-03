# frozen_string_literal: true

require "test_helper"

class PopulateGradeBookTest < ActiveSupport::TestCase
  setup do
    @classroom = create(:classroom)
    @grade_book = create(:grade_book, classroom: @classroom)
  end

  test "creates one entry per student in the classroom" do
    students = create_list(:student, 3, classroom: @classroom)

    PopulateGradeBook.execute(@grade_book)

    assert_equal students.map(&:id).sort, @grade_book.grade_entries.reload.pluck(:user_id).sort
  end

  test "is idempotent: running twice does not duplicate entries" do
    create_list(:student, 3, classroom: @classroom)

    PopulateGradeBook.execute(@grade_book)

    assert_no_changes -> { GradeEntry.count } do
      PopulateGradeBook.execute(@grade_book)
    end
  end

  test "does not disturb grades already entered" do
    student = create(:student, classroom: @classroom)
    entry = @grade_book.grade_entries.create!(user: student, math_grade: "A", attendance_days: 40)

    PopulateGradeBook.execute(@grade_book)

    entry.reload

    assert_equal "A", entry.math_grade
    assert_equal 40, entry.attendance_days
  end

  test "adds a student who joined after the first run" do
    create_list(:student, 2, classroom: @classroom)
    PopulateGradeBook.execute(@grade_book)

    late_joiner = create(:student, classroom: @classroom)

    assert_equal 1, PopulateGradeBook.execute(@grade_book)
    assert_includes @grade_book.grade_entries.reload.pluck(:user_id), late_joiner.id
  end

  test "creates entries for students only, not teachers or admins" do
    student = create(:student, classroom: @classroom)
    create(:teacher, classroom: @classroom)
    create(:admin, classroom: @classroom)

    PopulateGradeBook.execute(@grade_book)

    assert_equal [student.id], @grade_book.grade_entries.reload.pluck(:user_id)
  end

  test "refuses to touch a completed grade book" do
    create(:student, classroom: @classroom)
    @grade_book.completed!

    assert_no_changes -> { GradeEntry.count } do
      assert_not PopulateGradeBook.execute(@grade_book)
    end
  end

  test "reports how many entries it created" do
    create_list(:student, 2, classroom: @classroom)

    assert_equal 2, PopulateGradeBook.execute(@grade_book)
    assert_equal 0, PopulateGradeBook.execute(@grade_book)
  end
end
