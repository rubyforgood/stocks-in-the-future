# frozen_string_literal: true

require "test_helper"

# The door on a finalized grade book: writes are refused, and only an admin can open it.
#
# **Every one of these is a request, not a helper call.** The hole this closes was invisible to the view -
# the inputs simply stopped rendering - so a test that checks what the page offers would have passed
# throughout. Measured before the guard: a teacher PATCHed a completed book and moved a grade from C to A,
# days from 3 to 40 and the perfect-attendance flag to true.
class GradeBookReopenTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def a_finalized_book
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    student = create(:student, :with_portfolio, classroom:)
    book = classroom.grade_books.first
    entry = create(
      :grade_entry, grade_book: book, user: student, math_grade: "C", reading_grade: nil,
                    attendance_days: 3, is_perfect_attendance: false
    )

    book.verified!
    DistributeEarnings.execute(book)

    [classroom, book.reload, entry, teacher, student]
  end

  test "a finalized book refuses writes, whoever asks" do
    classroom, book, entry, teacher, = a_finalized_book

    [teacher, create(:admin)].each do |user|
      sign_in user
      patch classroom_grade_book_path(classroom, book),
            params: { grade_entries: { entry.id.to_s => { math_grade: "A", attendance_days: 40 } } }

      assert_redirected_to classroom_grade_book_path(classroom, book)
      assert_equal "This grade book is finalized. An admin can reopen it to make corrections.",
                   flash[:alert]
      assert_equal "C", entry.reload.math_grade, "the entry was rewritten on a book that had paid out"
      assert_equal 3, entry.attendance_days
    end
  end

  test "a teacher cannot reopen" do
    classroom, book, _entry, teacher, = a_finalized_book
    sign_in teacher

    post reopen_classroom_grade_book_path(classroom, book)

    assert_predicate book.reload, :completed?
  end

  test "an admin reopens it, the money does not move, and writes are accepted again" do
    classroom, book, entry, _teacher, student = a_finalized_book
    paid = student.portfolio.reload.cash_balance_cents

    assert_equal 60, paid, "20 a day for three days; the C earns nothing"

    sign_in create(:admin)
    post reopen_classroom_grade_book_path(classroom, book)

    assert_predicate book.reload, :draft?
    assert_equal paid, student.portfolio.reload.cash_balance_cents, "reopening must not touch the ledger"
    assert_predicate book, :paid?

    patch classroom_grade_book_path(classroom, book),
          params: { grade_entries: { entry.id.to_s => { math_grade: "A" } } }

    assert_equal "A", entry.reload.math_grade
  end

  test "reopening a book that was never finalized is refused" do
    classroom = create(:classroom)
    book = classroom.grade_books.first
    sign_in create(:admin)

    post reopen_classroom_grade_book_path(classroom, book)

    assert_equal "That grade book is not finalized, so there is nothing to reopen.", flash[:alert]
    assert_predicate book.reload, :draft?
  end

  test "finalizing again pays only the difference" do
    classroom, book, entry, _teacher, student = a_finalized_book
    sign_in create(:admin)

    post reopen_classroom_grade_book_path(classroom, book)
    patch classroom_grade_book_path(classroom, book),
          params: { grade_entries: { entry.id.to_s => { math_grade: "A" } } }
    post finalize_classroom_grade_book_path(classroom, book)

    # 60 already paid for three days, plus 300 for the A. Not 360 on top of 60.
    assert_equal 360, student.portfolio.reload.cash_balance_cents
    assert_predicate book.reload, :completed?
  end
end
