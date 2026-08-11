# frozen_string_literal: true

require "test_helper"

# Reopening a paid grade book, and paying only the difference.
#
# **Every amount here is a literal**, for the reason the characterisation test states: expectations derived
# from `GradeEntry`'s constants agree with whatever the code does, which is the one thing a test about money
# must not do.
#
# What this is guarding against is concrete. `finalize` used to deposit the full computed amount every time
# and had no notion of having run before, so returning a book to draft and finalizing again paid everybody
# twice. Nothing could reopen a book, so nothing exercised it - the bug was one admin action away the whole
# time.
class ReopenAndSettleTest < ActiveSupport::TestCase
  # Read off the code and confirmed by running it, not assumed: a C in maths earns **0**, a B **200**, an A
  # **300**, and attendance pays **20** a day. My first draft of this file guessed 100 a day and every
  # example failed at 240 against an expected 400 - which is the whole reason a money test states literals
  # and never derives them from the constants it is checking.
  def a_paid_book(math_grade:, attendance_days:)
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:)
    book = classroom.grade_books.first
    entry = create(
      :grade_entry, grade_book: book, user: student, math_grade:, reading_grade: nil,
                    attendance_days:, is_perfect_attendance: false
    )

    book.verified!
    DistributeEarnings.execute(book)

    [book.reload, entry.reload, student.portfolio.reload]
  end

  test "a first finalize pays the whole amount, and tags it with the book" do
    book, _entry, portfolio = a_paid_book(math_grade: "B", attendance_days: 2)

    assert_equal 240, portfolio.cash_balance_cents, "200 for the B plus 20 a day for two days"
    assert_equal 240, book.amount_paid_cents
    assert book.paid?
    assert_equal [book.id], portfolio.portfolio_transactions.pluck(:grade_book_id).uniq
  end

  test "reopening changes no money" do
    book, _entry, portfolio = a_paid_book(math_grade: "B", attendance_days: 2)

    book.draft!

    assert_equal 240, portfolio.reload.cash_balance_cents
    assert_equal 240, book.amount_paid_cents, "the ledger does not care about the status"
    assert book.paid?, "a reopened book has still paid"
  end

  test "a correction upward pays only the difference" do
    book, entry, portfolio = a_paid_book(math_grade: "B", attendance_days: 2)

    book.draft!
    entry.update!(math_grade: "A")
    book.verified!
    DistributeEarnings.execute(book)

    # 300 for the A rather than 200 for the B, so 100 more - not another 240.
    assert_equal 340, portfolio.reload.cash_balance_cents
    assert_equal 340, book.reload.amount_paid_cents
    assert_equal 100, portfolio.portfolio_transactions.where(reason: :math_earnings).last.amount_cents
  end

  test "a correction downward takes nothing back, and reports the overpayment" do
    book, entry, portfolio = a_paid_book(math_grade: "A", attendance_days: 2)

    assert_equal 340, portfolio.cash_balance_cents, "300 for the A plus 40 for two days"

    book.draft!
    entry.update!(math_grade: "C")
    book.verified!
    result = DistributeEarnings.execute(book)

    assert_equal 340, portfolio.reload.cash_balance_cents,
                 "money already in a portfolio is never withdrawn: it may have been spent on shares"
    assert_equal 300, result.overpaid_cents, "the A paid 300 for a grade that now earns nothing"
  end

  test "re-finalizing an unchanged book pays nothing at all" do
    book, _entry, portfolio = a_paid_book(math_grade: "B", attendance_days: 2)
    before = portfolio.portfolio_transactions.count

    book.draft!
    book.verified!
    DistributeEarnings.execute(book)

    assert_equal 240, portfolio.reload.cash_balance_cents
    assert_equal before, portfolio.portfolio_transactions.count, "no zero-value rows"
  end

  test "the difference is per reason, so a maths correction leaves attendance alone" do
    book, entry, portfolio = a_paid_book(math_grade: "B", attendance_days: 2)

    book.draft!
    entry.update!(math_grade: "A", attendance_days: 3)
    book.verified!
    DistributeEarnings.execute(book)

    by_reason = portfolio.portfolio_transactions.group(:reason).sum(:amount_cents)

    assert_equal 300, by_reason["math_earnings"], "200 for the B, then 100 for the A"
    assert_equal 60, by_reason["attendance_earnings"], "40 for two days, then 20 for the third"
    assert_equal 360, portfolio.reload.cash_balance_cents
  end
end
