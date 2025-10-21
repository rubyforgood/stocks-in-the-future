# frozen_string_literal: true

# test/models/grade_book_test.rb
require "test_helper"

class GradeBookTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:grade_book).validate!
  end

  test "default status is draft" do
    book = create(:grade_book)
    assert_equal "draft", book.status
    assert_predicate book, :draft?
  end

  test "status enum transitions work" do
    book = create(:grade_book)
    book.verified!
    assert_equal "verified", book.status
    assert_predicate book, :verified?

    book.completed!
    assert_equal "completed", book.status
    assert_predicate book, :completed?
  end

  test "gradebook is not finalizable? if any entry is not finalizable" do
    finalizeable_entry = build(:grade_entry, math_grade: "A", reading_grade: "B", attendance_days: 30)
    incomplete_entry = build(:grade_entry, math_grade: nil, reading_grade: "C", attendance_days: 25)
    book = build(:grade_book, grade_entries: [finalizeable_entry, incomplete_entry])

    assert finalizeable_entry.finalizable?
    assert_not incomplete_entry.finalizable?
    assert_not book.finalizable?
  end

  test "gradebook is finalizable? if all entries are finalizable" do
    book = build(
      :grade_book,
      grade_entries: build_list(:grade_entry, 3, math_grade: "A", reading_grade: "B", attendance_days: 30)
    )

    assert_not_empty book.grade_entries
    assert book.finalizable?
  end

  test "gradebook is not finalizable? if complete" do
    book = build(
      :grade_book,
      status: :completed,
      grade_entries: build_list(:grade_entry, 3, math_grade: "A", reading_grade: "B", attendance_days: 30)
    )
    assert_not book.finalizable?
  end
end
