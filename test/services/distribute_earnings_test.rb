# frozen_string_literal: true

require "test_helper"

class DistributeEarningsTest < ActiveSupport::TestCase
  test "only processes verified grade books" do
    draft_grade_book = create(:grade_book, status: :draft)
    completed_grade_book = create(:grade_book, status: :completed)

    assert_no_changes -> { PortfolioTransaction.count } do
      [draft_grade_book, completed_grade_book].each do |grade_book|
        DistributeEarnings.execute(grade_book)
      end

      assert draft_grade_book.draft?
      assert completed_grade_book.completed?
    end
  end

  test "skips transactions with zero earnings" do
    student = create(:student)
    grade_book = create(:grade_book, status: :verified)
    create(:grade_entry, grade_book: grade_book, user: student, attendance_days: 0, math_grade: "F", reading_grade: "F")

    assert_no_difference -> { student.portfolio.portfolio_transactions.count } do
      DistributeEarnings.execute(grade_book)
    end
  end

  test "distributes earnings as separate transactions by category" do
    school_year = create(:school_year)
    previous_quarter = create(:quarter, number: 1, school_year:)
    current_quarter = create(:quarter, number: 2, school_year:)

    student = create(:student)
    classroom = create(:classroom)

    previous_grade_book = create(:grade_book, quarter: previous_quarter, classroom: classroom)
    create(:grade_entry,
           grade_book: previous_grade_book,
           user: student,
           attendance_days: 6,
           math_grade: "C",
           reading_grade: "C")
    previous_grade_book.completed!

    current_grade_book = create(:grade_book, quarter: current_quarter, classroom: classroom, status: :verified)
    current_entry = create(:grade_entry,
                           grade_book: current_grade_book,
                           user: student,
                           attendance_days: 12,
                           math_grade: "B",
                           reading_grade: "A")

    DistributeEarnings.execute(current_grade_book)

    current_grade_book.reload
    assert current_grade_book.completed?

    transactions = student.portfolio.portfolio_transactions
    assert_equal 3, transactions.count

    expected_attendance = current_entry.earnings_for_attendance
    expected_math = GradeEntry::EARNINGS_FOR_B_GRADE + GradeEntry::EARNINGS_FOR_IMPROVED_GRADE
    expected_reading = GradeEntry::EARNINGS_FOR_A_GRADE + GradeEntry::EARNINGS_FOR_IMPROVED_GRADE

    attendance_transaction = transactions.find { |t| t.reason == PortfolioTransaction::REASONS[:attendance_earnings] }
    assert_not_nil attendance_transaction
    assert_equal expected_attendance, attendance_transaction.amount_cents
    assert attendance_transaction.deposit?

    math_transaction = transactions.find { |t| t.reason == PortfolioTransaction::REASONS[:math_earnings] }
    assert_not_nil math_transaction
    assert_equal expected_math, math_transaction.amount_cents
    assert math_transaction.deposit?

    reading_transaction = transactions.find { |t| t.reason == PortfolioTransaction::REASONS[:reading_earnings] }
    assert_not_nil reading_transaction
    assert_equal expected_reading, reading_transaction.amount_cents
    assert reading_transaction.deposit?
  end
end
