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
      earnings = EarningsCalculator.execute(entry, previous_entry)

      earnings.by_reason.each do |reason, amount_cents|
        distribute_earnings(entry.user, amount_cents, reason)
      end
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
      reason: reason_key
    )
  end
end
