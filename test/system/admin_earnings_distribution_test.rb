# frozen_string_literal: true

require "application_system_test_case"

class AdminEarningsDistributionTest < ApplicationSystemTestCase
  test "admin finalizes grade book and distributes earnings" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    initial_balance = (portfolio.cash_balance * 100).to_i

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 20,
      is_perfect_attendance: false,
      math_grade: "A",
      reading_grade: "B"
    )

    assert grade_book.verified?, "Grade book should be verified before finalization"
    assert_equal 0, portfolio.portfolio_transactions.count, "Student should have no transactions initially"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference -> { PortfolioTransaction.count } => 3,
                      -> { GradeBook.completed.count } => 1 do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    grade_book.reload
    assert grade_book.completed?, "Grade book status should be completed"

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload
    assert_equal 3, transactions.count, "Should have 3 transactions (attendance, math, reading)"

    expected_attendance = grade_entry.earnings_for_attendance
    expected_math = GradeEntry::EARNINGS_FOR_A_GRADE
    expected_reading = GradeEntry::EARNINGS_FOR_B_GRADE
    expected_total = expected_attendance + expected_math + expected_reading

    current_balance = (portfolio.cash_balance * 100).to_i
    assert current_balance > initial_balance, "Cash balance should increase"
    assert_equal initial_balance + expected_total, current_balance

    assert transactions.find(&:attendance_earnings?).present?
    assert transactions.find(&:math_earnings?).present?
    assert transactions.find(&:reading_earnings?).present?

    sign_out(admin)
  end

  test "attendance earnings calculated correctly" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    attendance_days = 25
    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: attendance_days,
      is_perfect_attendance: false,
      math_grade: nil,
      reading_grade: nil
    )

    expected_attendance_earnings = attendance_days * GradeEntry::EARNINGS_PER_DAY_ATTENDANCE

    assert_equal expected_attendance_earnings, grade_entry.earnings_for_attendance
    assert_equal 0, grade_entry.attendance_perfect_earnings, "Should have no perfect attendance bonus"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 1) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transaction = portfolio.portfolio_transactions.last

    assert transaction.attendance_earnings?, "Transaction should be for attendance earnings"
    assert_equal expected_attendance_earnings, transaction.amount_cents
    assert transaction.deposit?
    assert_equal expected_attendance_earnings, (portfolio.cash_balance * 100).to_i

    sign_out(admin)
  end

  test "perfect attendance bonus awarded" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    attendance_days = 30
    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: attendance_days,
      is_perfect_attendance: true,
      math_grade: nil,
      reading_grade: nil
    )

    base_attendance_earnings = attendance_days * GradeEntry::EARNINGS_PER_DAY_ATTENDANCE
    perfect_bonus = GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE
    expected_total = base_attendance_earnings + perfect_bonus

    assert grade_entry.is_perfect_attendance?, "Student should have perfect attendance"
    assert_equal perfect_bonus, grade_entry.attendance_perfect_earnings

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 1) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transaction = portfolio.portfolio_transactions.last

    assert transaction.attendance_earnings?
    assert_equal expected_total, transaction.amount_cents,
                 "Transaction should include base attendance ($#{base_attendance_earnings / 100.0}) " \
                 "and perfect bonus ($#{perfect_bonus / 100.0})"
    assert_equal expected_total, (portfolio.cash_balance * 100).to_i

    sign_out(admin)
  end

  test "A grade earnings calculated correctly" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 0,
      math_grade: "A",
      reading_grade: "A-"
    )

    expected_math_earnings = GradeEntry::EARNINGS_FOR_A_GRADE
    expected_reading_earnings = GradeEntry::EARNINGS_FOR_A_GRADE

    assert_equal expected_math_earnings, grade_entry.earnings_for_math
    assert_equal expected_reading_earnings, grade_entry.earnings_for_reading

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 2) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    math_transaction = transactions.find(&:math_earnings?)
    reading_transaction = transactions.find(&:reading_earnings?)

    assert_not_nil math_transaction, "Should have math earnings transaction"
    assert_equal expected_math_earnings, math_transaction.amount_cents
    assert math_transaction.deposit?

    assert_not_nil reading_transaction, "Should have reading earnings transaction"
    assert_equal expected_reading_earnings, reading_transaction.amount_cents
    assert reading_transaction.deposit?

    assert_equal expected_math_earnings + expected_reading_earnings, (portfolio.cash_balance * 100).to_i

    sign_out(admin)
  end

  test "B grade earnings calculated correctly" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 0,
      math_grade: "B+",
      reading_grade: "B"
    )

    expected_math_earnings = GradeEntry::EARNINGS_FOR_B_GRADE
    expected_reading_earnings = GradeEntry::EARNINGS_FOR_B_GRADE

    assert_equal expected_math_earnings, grade_entry.earnings_for_math
    assert_equal expected_reading_earnings, grade_entry.earnings_for_reading

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 2) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    math_transaction = transactions.find(&:math_earnings?)
    reading_transaction = transactions.find(&:reading_earnings?)

    assert_not_nil math_transaction
    assert_equal expected_math_earnings, math_transaction.amount_cents

    assert_not_nil reading_transaction
    assert_equal expected_reading_earnings, reading_transaction.amount_cents

    assert_equal expected_math_earnings + expected_reading_earnings, (portfolio.cash_balance * 100).to_i

    sign_out(admin)
  end

  test "no earnings for grades below B" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    attendance_days = 10
    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: attendance_days,
      math_grade: "C",
      reading_grade: "F"
    )

    expected_attendance_only = attendance_days * GradeEntry::EARNINGS_PER_DAY_ATTENDANCE

    assert_equal 0, grade_entry.earnings_for_math, "C grade should earn $0"
    assert_equal 0, grade_entry.earnings_for_reading, "F grade should earn $0"
    assert_equal expected_attendance_only, grade_entry.earnings_for_attendance

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 1) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    assert_equal 1, transactions.count, "Should only have attendance transaction"
    assert transactions.find(&:attendance_earnings?).present?
    assert_nil transactions.find(&:math_earnings?), "Should have no math earnings"
    assert_nil transactions.find(&:reading_earnings?), "Should have no reading earnings"

    assert_equal expected_attendance_only, (portfolio.cash_balance * 100).to_i

    sign_out(admin)
  end

  test "grade improvement bonus awarded" do
    # Setup
    admin = create(:admin)
    school_year = create(:school_year)
    quarter1 = create(:quarter, number: 1, school_year: school_year)
    quarter2 = create(:quarter, number: 2, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # Previous quarter with lower grades
    previous_grade_book = create(
      :grade_book,
      quarter: quarter1,
      classroom: classroom,
      status: :completed
    )

    previous_entry = create(
      :grade_entry,
      grade_book: previous_grade_book,
      user: student,
      math_grade: "C",
      reading_grade: "B"
    )

    # Current quarter with improved grades
    current_grade_book = create(
      :grade_book,
      quarter: quarter2,
      classroom: classroom,
      status: :verified
    )

    current_entry = create(
      :grade_entry,
      grade_book: current_grade_book,
      user: student,
      attendance_days: 0,
      math_grade: "B",
      reading_grade: "A"
    )

    improvement_bonus = GradeEntry::EARNINGS_FOR_IMPROVED_GRADE
    expected_math = GradeEntry::EARNINGS_FOR_B_GRADE + improvement_bonus
    expected_reading = GradeEntry::EARNINGS_FOR_A_GRADE + improvement_bonus

    assert_equal improvement_bonus, current_entry.math_improvement_earnings(previous_entry),
                 "Math improved from C to B, should get bonus"
    assert_equal improvement_bonus, current_entry.reading_improvement_earnings(previous_entry),
                 "Reading improved from B to A, should get bonus"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, current_grade_book)

    assert_difference("PortfolioTransaction.count", 2) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    math_transaction = transactions.find(&:math_earnings?)
    reading_transaction = transactions.find(&:reading_earnings?)

    assert_not_nil math_transaction
    assert_equal expected_math, math_transaction.amount_cents,
                 "Math should be base B grade ($2.00) + improvement bonus ($2.00) = $4.00"

    assert_not_nil reading_transaction
    assert_equal expected_reading, reading_transaction.amount_cents,
                 "Reading should be base A grade ($3.00) + improvement bonus ($2.00) = $5.00"

    sign_out(admin)
  end

  test "no improvement bonus for first quarter" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    # First quarter - no previous quarter exists
    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    grade_entry = create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 0,
      math_grade: "A",
      reading_grade: "A"
    )

    expected_math = GradeEntry::EARNINGS_FOR_A_GRADE
    expected_reading = GradeEntry::EARNINGS_FOR_A_GRADE

    assert_equal 1, quarter.number, "This is first quarter"
    assert_nil quarter.previous, "No previous quarter should exist"
    assert_equal 0, grade_entry.math_improvement_earnings(nil), "No improvement bonus without previous entry"
    assert_equal 0, grade_entry.reading_improvement_earnings(nil), "No improvement bonus without previous entry"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 2) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    math_transaction = transactions.find(&:math_earnings?)
    reading_transaction = transactions.find(&:reading_earnings?)

    # Should only receive base A grade earnings, no improvement bonus
    assert_equal expected_math, math_transaction.amount_cents,
                 "Math should only be base A grade ($3.00) with no improvement bonus"
    assert_equal expected_reading, reading_transaction.amount_cents,
                 "Reading should only be base A grade ($3.00) with no improvement bonus"

    sign_out(admin)
  end

  test "multiple students receive individual earnings" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)

    # Student 1: High grades and perfect attendance
    student1 = create(:student, :with_portfolio, classroom: classroom)
    student1.reload
    portfolio1 = student1.portfolio

    # Student 2: Average grades and some attendance
    student2 = create(:student, :with_portfolio, classroom: classroom)
    student2.reload
    portfolio2 = student2.portfolio

    # Student 3: Low grades and poor attendance
    student3 = create(:student, :with_portfolio, classroom: classroom)
    student3.reload
    portfolio3 = student3.portfolio

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    entry1 = create(
      :grade_entry,
      grade_book: grade_book,
      user: student1,
      attendance_days: 30,
      is_perfect_attendance: true,
      math_grade: "A",
      reading_grade: "A"
    )

    entry2 = create(
      :grade_entry,
      grade_book: grade_book,
      user: student2,
      attendance_days: 20,
      is_perfect_attendance: false,
      math_grade: "B",
      reading_grade: "B"
    )

    entry3 = create(
      :grade_entry,
      grade_book: grade_book,
      user: student3,
      attendance_days: 5,
      is_perfect_attendance: false,
      math_grade: "D",
      reading_grade: "F"
    )

    student1_expected = entry1.earnings_for_attendance +
                        entry1.attendance_perfect_earnings +
                        entry1.earnings_for_math +
                        entry1.earnings_for_reading

    student2_expected = entry2.earnings_for_attendance +
                        entry2.earnings_for_math +
                        entry2.earnings_for_reading

    student3_expected = entry3.earnings_for_attendance

    assert student1_expected > student2_expected, "Student 1 should earn more than Student 2"
    assert student2_expected > student3_expected, "Student 2 should earn more than Student 3"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    expected_transaction_count = 3 + 3 + 1 # student1 (3) + student2 (3) + student3 (1)
    assert_difference("PortfolioTransaction.count", expected_transaction_count) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio1.reload
    portfolio2.reload
    portfolio3.reload

    assert_equal student1_expected, (portfolio1.cash_balance * 100).to_i,
                 "Student 1 balance should match expected earnings"
    assert_equal student2_expected, (portfolio2.cash_balance * 100).to_i,
                 "Student 2 balance should match expected earnings"
    assert_equal student3_expected, (portfolio3.cash_balance * 100).to_i,
                 "Student 3 balance should match expected earnings"

    assert_equal 3, portfolio1.portfolio_transactions.count, "Student 1 should have 3 transactions"
    assert_equal 3, portfolio2.portfolio_transactions.count, "Student 2 should have 3 transactions"
    assert_equal 1, portfolio3.portfolio_transactions.count, "Student 3 should have 1 transaction (attendance only)"

    sign_out(admin)
  end

  test "earnings distribution creates separate transactions per category" do
    # Setup
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload
    portfolio = student.portfolio

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :verified
    )

    create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 15,
      math_grade: "A",
      reading_grade: "B"
    )

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_difference("PortfolioTransaction.count", 3) do
      accept_confirm do
        click_on "Finalize Grades"
      end

      assert_text "Grade book finalized. Funds have been distributed."
    end

    portfolio.reload
    transactions = portfolio.portfolio_transactions.reload

    assert_equal 3, transactions.count, "Should have exactly 3 separate transactions"

    # Verify each transaction type exists and is distinct
    attendance_tx = transactions.find(&:attendance_earnings?)
    math_tx = transactions.find(&:math_earnings?)
    reading_tx = transactions.find(&:reading_earnings?)

    assert_not_nil attendance_tx, "Should have attendance earnings transaction"
    assert_not_nil math_tx, "Should have math earnings transaction"
    assert_not_nil reading_tx, "Should have reading earnings transaction"

    [attendance_tx, math_tx, reading_tx].each do |tx|
      assert tx.deposit?, "all tx should be deposit: #{tx}"
    end

    # Verify they have different reasons
    assert_equal :attendance_earnings, attendance_tx.reason.to_sym
    assert_equal :math_earnings, math_tx.reason.to_sym
    assert_equal :reading_earnings, reading_tx.reason.to_sym

    sign_out(admin)
  end

  test "grade book cannot be finalized twice" do
    admin = create(:admin)
    school_year = create(:school_year)
    quarter = create(:quarter, number: 1, school_year: school_year)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom: classroom)
    student.reload

    grade_book = create(
      :grade_book,
      quarter: quarter,
      classroom: classroom,
      status: :completed
    )

    create(
      :grade_entry,
      grade_book: grade_book,
      user: student,
      attendance_days: 20,
      math_grade: "A",
      reading_grade: "A"
    )

    assert grade_book.completed?, "Grade book should already be completed"

    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    # Verification - Finalize button should not be visible
    assert_no_button "Finalize Grades"

    sign_out(admin)
  end
end
