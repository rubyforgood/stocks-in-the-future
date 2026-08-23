# frozen_string_literal: true

class GradeBook < ApplicationRecord
  belongs_to :quarter
  belongs_to :classroom
  has_many :grade_entries, dependent: :destroy

  # The deposits this book has made. `dependent: :nullify` rather than `:destroy`: a paid transaction is a
  # ledger entry and deleting a grade book must not remove money from a portfolio. The link is provenance,
  # not ownership.
  has_many :portfolio_transactions, dependent: :nullify

  enum :status, {
    draft: "draft",
    verified: "verified",
    completed: "completed"
  }

  # **"Has this paid?" is not the same question as "is this completed?"** - and after a reopen the status
  # says draft while the money is still out there. So it is derived from the ledger rather than from a
  # second column, which is also the only answer that cannot drift from what was actually deposited.
  #
  # A book where nobody earned anything creates no transactions and so reads as unpaid. That is harmless:
  # the only thing this gates is paying a difference, and the difference there is zero either way.
  def paid?
    portfolio_transactions.exists?
  end

  def paid_on
    portfolio_transactions.minimum(:created_at)
  end

  def amount_paid_cents
    portfolio_transactions.sum(:amount_cents)
  end

  # What this book has already paid one student, split by the reason it was paid for. The difference is
  # computed per reason because that is how the deposits are written - one row per reason - so a correction
  # to a maths grade tops up the maths reason and leaves the others alone.
  def paid_cents_by_reason_for(user)
    portfolio_transactions
      .where(portfolio: user.portfolio)
      .group(:reason)
      .sum(:amount_cents)
      .transform_keys(&:to_sym)
  end

  # The same student's entry in the previous quarter, keyed by user_id. Improvement earnings are paid
  # by comparing against it, so anything that shows a student what they will earn needs the same
  # lookup DistributeEarnings uses - it lived privately in that service, and a second copy in a view
  # is how a preview drifts from the payout it is previewing.
  #
  # index_by, not group_by: grade_entries is unique on [grade_book_id, user_id], so there is at most
  # one. The service used group_by and then `&.first`, which read as though there might be several.
  #
  # {} covers the first quarter of a school year and a classroom with no grade book last quarter.
  # Both mean "no improvement to pay".
  # The classroom's students who have no entry in this grade book yet - who "Add students" would add.
  #
  # PopulateGradeBook held this privately, so the view had no way to ask before offering the button. It
  # offered it unconditionally, and in a fully populated grade book - which is the normal state - the
  # button ran, added nobody, and flashed "Every student in this class already has a row". That message
  # is a `notice`, so it auto-dismissed after 6s and the button looked broken. Reported exactly that way.
  #
  # classroom.students, not users: users includes the teachers attached to the classroom, and grading a
  # teacher would pay a teacher. students is Student-typed and scoped to kept records.
  def students_missing_entries
    classroom.students.where.not(id: grade_entries.select(:user_id))
  end

  def previous_entries_by_user_id
    previous_quarter = quarter&.previous
    return {} unless previous_quarter

    previous_book = GradeBook.find_by(classroom: classroom, quarter: previous_quarter)
    return {} unless previous_book

    previous_book.grade_entries.includes(:user).index_by(&:user_id)
  end
end
