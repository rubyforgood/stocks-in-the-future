# frozen_string_literal: true

require "test_helper"

class DistributeFlatAllotmentTest < ActiveSupport::TestCase
  def setup
    @classroom = create(:classroom)
    @quarter = @classroom.school_year.quarters.find_by!(number: 2)
    @grade_book = @classroom.grade_books.find_by!(quarter: @quarter)
  end

  test "deposits the amount into every student's portfolio" do
    students = create_list(:student, 3, classroom: @classroom)

    assert_difference "PortfolioTransaction.count", 3 do
      DistributeFlatAllotment.execute(@grade_book, 750)
    end

    students.each do |student|
      transaction = student.portfolio.portfolio_transactions.last

      assert_equal 750, transaction.amount_cents
      assert_equal "deposit", transaction.transaction_type
      assert_equal "administrative_adjustments", transaction.reason
      assert_equal "Flat allotment for Q2", transaction.description
    end
  end

  test "returns the number of students paid" do
    create_list(:student, 2, classroom: @classroom)

    assert_equal 2, DistributeFlatAllotment.execute(@grade_book, 100)
  end

  test "does nothing for a zero or negative amount" do
    create(:student, classroom: @classroom)

    assert_no_difference "PortfolioTransaction.count" do
      assert_equal 0, DistributeFlatAllotment.execute(@grade_book, 0)
      assert_equal 0, DistributeFlatAllotment.execute(@grade_book, -500)
    end
  end

  test "pays students regardless of whether they have a grade entry" do
    with_entry = create(:student, classroom: @classroom)
    without_entry = create(:student, classroom: @classroom)
    create(:grade_entry, grade_book: @grade_book, user: with_entry)

    DistributeFlatAllotment.execute(@grade_book, 250)

    [with_entry, without_entry].each do |student|
      assert_equal 250, student.portfolio.portfolio_transactions.last.amount_cents
    end
  end

  test "does not pay students from another classroom" do
    other_student = create(:student, classroom: create(:classroom))
    create(:student, classroom: @classroom)

    assert_difference "PortfolioTransaction.count", 1 do
      DistributeFlatAllotment.execute(@grade_book, 100)
    end

    assert_empty other_student.portfolio.portfolio_transactions
  end

  test "does not change the grade book status" do
    create(:student, classroom: @classroom)

    assert_no_changes -> { @grade_book.reload.status } do
      DistributeFlatAllotment.execute(@grade_book, 100)
    end
  end
end
