# frozen_string_literal: true

require "test_helper"

# Pins what DistributeEarnings pays today, before the calculation is extracted from
# it. Every amount below is a literal. Deriving them from GradeEntry's constants -
# as distribute_earnings_test.rb does - makes the test agree with whatever the code
# happens to do, which is the one thing a characterisation test must not do. If a
# constant changes on purpose, these numbers are supposed to fail and be re-read.
#
# Amounts are cents.
class DistributeEarningsCharacterisationTest < ActiveSupport::TestCase
  # Everything not named by a test contributes zero, so each test states only the
  # dimension it is pinning.
  NOTHING = { attendance_days: 0, math_grade: nil, reading_grade: nil, is_perfect_attendance: false }.freeze

  # previous: :none            - first quarter, so there is no previous quarter at all
  # previous: nil              - a previous quarter exists, but this student has no entry in it
  # previous: { math_grade: } - a previous entry exists with these grades
  #
  # Returns { reason => amount_cents } for the student's portfolio.
  def distribute(current:, previous: :none)
    classroom = create(:classroom)
    quarters = classroom.school_year.quarters
    student = create(:student, classroom: classroom)
    current_number = previous == :none ? 1 : 2

    unless previous == :none
      previous_book = classroom.grade_books.find_by!(quarter: quarters.find_by!(number: 1))
      create(:grade_entry, **NOTHING, **previous, grade_book: previous_book, user: student) if previous
      previous_book.completed!
    end

    current_book = classroom.grade_books.find_by!(quarter: quarters.find_by!(number: current_number))
    create(:grade_entry, **NOTHING, **current, grade_book: current_book, user: student)
    current_book.verified!

    DistributeEarnings.execute(current_book)

    student.portfolio.portfolio_transactions.to_h do |transaction|
      [transaction.reason.to_sym, transaction.amount_cents]
    end
  end

  test "attendance pays 20 cents a day" do
    assert_equal({ attendance_earnings: 240 }, distribute(current: { attendance_days: 12 }))
  end

  test "perfect attendance adds a flat dollar on top of the days" do
    assert_equal(
      { attendance_earnings: 340 },
      distribute(current: { attendance_days: 12, is_perfect_attendance: true })
    )
  end

  test "perfect attendance alone pays the flat dollar" do
    assert_equal(
      { attendance_earnings: 100 },
      distribute(current: { attendance_days: 0, is_perfect_attendance: true })
    )
  end

  test "blank attendance days pays nothing at all" do
    assert_empty distribute(current: { attendance_days: nil })
  end

  test "each grade band pays a fixed amount, with no previous quarter" do
    expected = {
      "A+" => 300, "A" => 300, "A-" => 300,
      "B+" => 200, "B" => 200, "B-" => 200,
      "C+" => 0, "C" => 0, "C-" => 0, "D" => 0, "F" => 0
    }

    assert_equal GradeEntry::GRADE_OPTIONS.sort, expected.keys.sort, "a grade band is unpinned"

    expected.each do |grade, cents|
      amounts = distribute(current: { math_grade: grade })

      assert_equal(cents.zero? ? {} : { math_earnings: cents }, amounts, "math grade #{grade}")
    end
  end

  test "reading is paid on the same bands, as its own transaction" do
    assert_equal({ reading_earnings: 300 }, distribute(current: { reading_grade: "A-" }))
    assert_equal({ reading_earnings: 200 }, distribute(current: { reading_grade: "B-" }))
    assert_empty distribute(current: { reading_grade: "C" })
  end

  test "a quarter with nothing before it pays no improvement, however good the grade" do
    assert_equal({ math_earnings: 300 }, distribute(current: { math_grade: "A" }))
  end

  # Quarter#previous for quarter 1 does not return nil: it falls back to quarter 4 of
  # the previous school year at the same school. What makes quarter 1 improvement-free
  # is one level down - a classroom belongs to a single school year and only has grade
  # books for that year's quarters, so find_previous_entries looks for a grade book
  # that cannot exist and gets {}. Worth pinning, because someone giving classrooms
  # grade books across years would silently switch improvement on in quarter 1.
  test "quarter 1 pays no improvement even when the school has a previous year" do
    school = create(:school)
    create(:school_year, school: school, year: create(:year, name: "2023 - 2024"))
    current_school_year = create(:school_year, school: school, year: create(:year, name: "2024 - 2025"))

    classroom = create(:classroom, school_year: current_school_year)
    student = create(:student, classroom: classroom)
    first_quarter = current_school_year.quarters.find_by!(number: 1)

    assert_not_nil first_quarter.previous, "expected quarter 1 to reach back into the previous year"

    grade_book = classroom.grade_books.find_by!(quarter: first_quarter)
    create(:grade_entry, **NOTHING, math_grade: "A", grade_book: grade_book, user: student)
    grade_book.verified!

    DistributeEarnings.execute(grade_book)

    assert_equal 300, student.portfolio.portfolio_transactions.find_by!(reason: :math_earnings).amount_cents
  end

  test "improving on the previous quarter adds two dollars" do
    assert_equal(
      { math_earnings: 400 },
      distribute(current: { math_grade: "B" }, previous: { math_grade: "C" })
    )
  end

  test "improving within a band still counts as improvement" do
    assert_equal(
      { math_earnings: 500 },
      distribute(current: { math_grade: "A" }, previous: { math_grade: "A-" })
    )
  end

  test "an unchanged grade pays no improvement" do
    assert_equal(
      { math_earnings: 200 },
      distribute(current: { math_grade: "B" }, previous: { math_grade: "B" })
    )
  end

  test "a worse grade pays no improvement" do
    assert_equal(
      { math_earnings: 200 },
      distribute(current: { math_grade: "B" }, previous: { math_grade: "A" })
    )
  end

  test "improvement is paid even when the new grade earns nothing by itself" do
    assert_equal(
      { math_earnings: 200 },
      distribute(current: { math_grade: "D" }, previous: { math_grade: "F" })
    )
  end

  test "a previous quarter with no entry for this student pays no improvement" do
    assert_equal({ math_earnings: 300 }, distribute(current: { math_grade: "A" }, previous: nil))
  end

  test "a blank previous grade pays no improvement" do
    assert_equal(
      { math_earnings: 300 },
      distribute(current: { math_grade: "A" }, previous: { math_grade: nil })
    )
  end

  test "a blank current grade pays nothing, even against a previous grade" do
    assert_empty distribute(current: { math_grade: nil }, previous: { math_grade: "F" })
  end

  test "math and reading improve independently" do
    assert_equal(
      { math_earnings: 400, reading_earnings: 200 },
      distribute(
        current: { math_grade: "B", reading_grade: "B" },
        previous: { math_grade: "C", reading_grade: "B" }
      )
    )
  end

  test "the three categories are separate deposits, and the book is completed" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    grade_book = classroom.grade_books.find_by!(quarter: classroom.school_year.quarters.find_by!(number: 1))
    create(
      :grade_entry, grade_book: grade_book, user: student,
                    attendance_days: 10, math_grade: "A", reading_grade: "B", is_perfect_attendance: true
    )
    grade_book.verified!

    DistributeEarnings.execute(grade_book)

    transactions = student.portfolio.portfolio_transactions

    assert_equal 3, transactions.count
    assert(transactions.all?(&:deposit?))
    assert_equal 300, transactions.find_by!(reason: :attendance_earnings).amount_cents
    assert_equal 300, transactions.find_by!(reason: :math_earnings).amount_cents
    assert_equal 200, transactions.find_by!(reason: :reading_earnings).amount_cents
    assert grade_book.reload.completed?
  end

  # **A completed grade book's figures never move again.**
  #
  # Its inputs are locked, so before perfect attendance was derived, what the page showed always equalled
  # what the ledger held. `quarters.school_days` lives outside the grade book and an admin can change it
  # at any time - so this pins the guarantee that keeps the page and the money in agreement.
  test "changing a quarter's school days does not move a finalized book's earnings" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:)
    book = classroom.grade_books.first
    book.quarter.update!(school_days: 45)
    entry = create(
      :grade_entry, grade_book: book, user: student,
                    attendance_days: 45, is_perfect_attendance: false
    )

    book.verified!
    DistributeEarnings.execute(book)
    paid = student.portfolio.reload.portfolio_transactions.sum(:amount_cents)

    # The derivation earned the bonus, and finalizing wrote that answer down.
    assert_predicate entry.reload, :is_perfect_attendance
    assert_equal GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE,
                 entry.attendance_perfect_earnings

    # Now somebody corrects the quarter. The ledger cannot change, and neither can the figure shown.
    book.quarter.update!(school_days: 90)

    assert_predicate entry.reload, :perfect_attendance?
    assert_equal GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE, entry.attendance_perfect_earnings
    assert_equal paid, student.portfolio.reload.portfolio_transactions.sum(:amount_cents)
  end

  test "finalizing writes down the answer it paid on, including a bonus it withdrew" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:)
    book = classroom.grade_books.first
    book.quarter.update!(school_days: 45)
    # The shape the seeds contained: flagged perfect, three days attended.
    entry = create(
      :grade_entry, grade_book: book, user: student,
                    attendance_days: 3, is_perfect_attendance: true
    )

    book.verified!
    DistributeEarnings.execute(book)

    assert_not entry.reload.is_perfect_attendance,
               "the book was finalized without the bonus, so the column has to say so"
    assert_equal 0, entry.attendance_perfect_earnings
  end

  test "a draft book still derives, so a corrected school-day count takes effect before payment" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:)
    book = classroom.grade_books.first
    book.quarter.update!(school_days: 45)
    entry = create(
      :grade_entry, grade_book: book, user: student,
                    attendance_days: 40, is_perfect_attendance: true
    )

    assert_not_predicate entry, :perfect_attendance?

    book.quarter.update!(school_days: 40)

    assert_predicate entry.reload, :perfect_attendance?
  end
end
