# frozen_string_literal: true

class DistributeEarnings
  def initialize(grade_book)
    @grade_book = grade_book
    @previous_entries = find_previous_entries
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    return unless @grade_book.verified?

    ActiveRecord::Base.transaction do
      distribute_funds_to_students
      @grade_book.completed!
    end
  end

  private

  def distribute_funds_to_students
    @grade_book.grade_entries.each do |entry|
      previous_entry = @previous_entries[entry.user_id]&.first

      distribute_earnings(entry.user, attendance_earnings(entry, previous_entry), :attendance_earnings)
      distribute_earnings(entry.user, math_earnings(entry, previous_entry), :math_earnings)
      distribute_earnings(entry.user, reading_earnings(entry, previous_entry), :reading_earnings)
    end
  end

  def find_previous_entries
    previous_quarter = @grade_book.quarter.previous
    return {} unless previous_quarter

    previous_grade_book = GradeBook.find_by(classroom: @grade_book.classroom, quarter: previous_quarter)
    return {} unless previous_grade_book

    previous_grade_book.grade_entries.to_a.group_by(&:user_id)
  end

  def distribute_earnings(user, amount_cents, reason_key)
    return if amount_cents.zero?

    user.portfolio.portfolio_transactions.create!(
      amount_cents: amount_cents,
      transaction_type: :deposit,
      reason: PortfolioTransaction::REASONS[reason_key]
    )
  end

  def attendance_earnings(entry, _previous_entry)
    [
      entry.earnings_for_attendance,
      entry.attendance_perfect_earnings
    ].sum
  end

  def math_earnings(entry, previous_entry)
    [
      entry.earnings_for_math,
      entry.math_improvement_earnings(previous_entry)
    ].sum
  end

  def reading_earnings(entry, previous_entry)
    [
      entry.earnings_for_reading,
      entry.reading_improvement_earnings(previous_entry)
    ].sum
  end
end
