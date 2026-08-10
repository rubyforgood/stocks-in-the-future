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
      freeze_attendance_answers
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

  # The derived answer becomes the stored one, in the same transaction as the deposits.
  #
  # After this the book is `completed?` and `GradeEntry#perfect_attendance?` reads the column rather than
  # deriving - so what the page shows is what was paid, whatever anyone later types into the quarter's
  # `school_days`. Written *before* `completed!`, because the derivation is what we are preserving and it
  # stops running the moment the status changes.
  def freeze_attendance_answers
    @grade_book.grade_entries.each do |entry|
      paid_on = entry.perfect_attendance?
      # `update!`, not `update_column`: this is a real change to the row, so it should be validated and
      # it should move `updated_at`. Inside the transaction, so a failure rolls the deposits back with it
      # rather than paying money against an answer that was never recorded.
      entry.update!(is_perfect_attendance: paid_on) unless entry.is_perfect_attendance == paid_on
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
