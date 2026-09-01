# frozen_string_literal: true

# Deposits the same amount into every student's portfolio in a grade book's
# classroom. Used when a school never sends grades for a quarter, so earnings
# cannot be calculated and every student is given a flat amount instead.
class DistributeFlatAllotment
  def initialize(grade_book, amount_cents)
    @grade_book = grade_book
    @amount_cents = amount_cents
  end

  def self.execute(...)
    new(...).execute
  end

  # @return [Integer] how many students were paid
  def execute
    return 0 unless @amount_cents.to_i.positive?

    ActiveRecord::Base.transaction do
      students.each { |student| deposit(student) }.size
    end
  end

  private

  def students
    @grade_book.classroom.students
  end

  def deposit(student)
    student.portfolio.portfolio_transactions.create!(
      amount_cents: @amount_cents,
      transaction_type: :deposit,
      reason: :administrative_adjustments,
      description: description
    )
  end

  def description
    "Flat allotment for Q#{@grade_book.quarter.number}"
  end
end
