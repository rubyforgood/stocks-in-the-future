# frozen_string_literal: true

# Pays a grade book's earnings into student portfolios.
#
# **It pays the difference, not the total.** On a first finalize the two are the same, because nothing has
# been paid yet - so the numbers pinned in `distribute_earnings_characterisation_test` are unchanged. The
# difference matters after an admin reopens a finalized book to correct it: what is owed on the corrected
# grades, minus what this book has already paid for that reason, is what gets deposited.
#
# Without that, reopening would pay everybody the whole amount a second time. The service used to have no
# notion of having run before, and the only thing stopping a double payment was that nothing could reopen.
#
# **A negative difference is never taken back.** A grade corrected downward leaves the overpayment paid:
# the student may have bought shares with the money, so the balance may not cover a reversal, and a balance
# that drops is a pedagogical event rather than a bookkeeping one. `overpaid_cents` reports it so a page can
# say so; nothing acts on it.
#
# Per reason, not per student total, because that is how the deposits are written - one row per reason - so
# a corrected maths grade tops up the maths reason and leaves attendance alone.
class DistributeEarnings
  def initialize(grade_book)
    @grade_book = grade_book
    @previous_entries = grade_book.previous_entries_by_user_id
    @overpaid_cents = 0
  end

  def self.execute(...)
    new(...).execute
  end

  attr_reader :overpaid_cents

  def execute
    return unless @grade_book.verified?

    ActiveRecord::Base.transaction do
      distribute_funds_to_students
      @grade_book.completed!
    end

    self
  end

  private

  def distribute_funds_to_students
    @grade_book.grade_entries.each { |entry| settle(entry) }
  end

  def settle(entry)
    owed = EarningsCalculator.execute(entry, @previous_entries[entry.user_id]).by_reason
    already_paid = @grade_book.paid_cents_by_reason_for(entry.user)

    # Every reason either side has an amount for: a reason that is owed nothing but was paid something is
    # how an overpayment shows up, and it has to be counted even though nothing is deposited for it.
    (owed.keys | already_paid.keys).each do |reason|
      difference = owed.fetch(reason, 0) - already_paid.fetch(reason, 0)

      if difference.negative?
        @overpaid_cents += difference.abs
      else
        deposit(entry.user, difference, reason)
      end
    end
  end

  def deposit(user, amount_cents, reason_key)
    return if amount_cents.zero?

    user.portfolio.portfolio_transactions.create!(
      amount_cents: amount_cents,
      transaction_type: :deposit,
      reason: reason_key,
      grade_book: @grade_book
    )
  end
end
