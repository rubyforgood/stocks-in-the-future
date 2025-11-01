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
end
