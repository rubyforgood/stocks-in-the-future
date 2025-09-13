# frozen_string_literal: true

require "test_helper"

class DistributeFundsTest < ActiveSupport::TestCase
  test "it does nothing if grade book is in draft" do
    grade_book = create(:grade_book, status: :draft)

    DistributeFunds.execute(grade_book)
    grade_book.reload
    assert grade_book.draft?
  end

  test "it does nothing if grade book is completed" do
    assert_no_changes -> { PortfolioTransaction.count } do
      grade_book = create(:grade_book, status: :completed)
      DistributeFunds.execute(grade_book)
      grade_book.reload
      assert grade_book.completed?
    end
  end

  test "it creates a deposit for students who based on their grades and attendance" do
    # First we create a previous quarter with a grade book and a student entry
    school_year = create(:school_year)
    last_quarter = create(:quarter, number: 1, school_year:)
    student = create(:student)
    previous_grade_book = create(:grade_book, quarter: last_quarter)
    create(:grade_entry, grade_book: previous_grade_book, user: student, attendance_days: 6, math_grade: "C",
                         reading_grade: "C")
    previous_grade_book.completed!

    # Now we create the current quarter and grade book with a grade entry for the same student
    current_quarter = create(:quarter, number: 2, school_year:)
    grade_book = create(:grade_book, quarter: current_quarter, classroom: previous_grade_book.classroom)
    create(:grade_entry, grade_book: grade_book, user: student, attendance_days: 12, math_grade: "B",
                         reading_grade: "A")
    grade_book.verified!

    assert_difference -> { student.portfolio.portfolio_transactions.count }, 1 do
      DistributeFunds.execute(grade_book)
    end

    grade_book.reload
    assert grade_book.completed?

    transaction = student.portfolio.portfolio_transactions.last
    attendance_earnings = 12 * GradeEntry::EARNINGS_PER_DAY_ATTENDANCE
    reading_earnings = GradeEntry::EARNINGS_FOR_A_GRADE
    math_earnings = GradeEntry::EARNINGS_FOR_B_GRADE
    improvement_earnings = 2 * GradeEntry::EARNINGS_FOR_IMPROVED_GRADE
    expected_total = attendance_earnings + reading_earnings + math_earnings + improvement_earnings

    assert_equal expected_total, transaction.amount_cents
    assert transaction.deposit?
  end
end
