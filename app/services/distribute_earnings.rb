# frozen_string_literal: true

class DistributeEarnings
  def initialize(grade_book)
    @grade_book = grade_book
    @previous_entries = grade_book.previous_entries_by_user_id
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
      previous_entry = @previous_entries[entry.user_id]
      earnings = EarningsCalculator.execute(entry, previous_entry)

      earnings.by_reason.each do |reason, amount_cents|
        distribute_earnings(entry.user, amount_cents, reason)
      end
    end
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
