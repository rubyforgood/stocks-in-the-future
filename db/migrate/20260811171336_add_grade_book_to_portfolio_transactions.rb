# frozen_string_literal: true

# Which grade book paid this deposit.
#
# Two things need it. A re-opened grade book has to pay only the *difference* between what is owed now and
# what it has already paid, and without this link that question cannot be asked at all. And it pairs an
# earnings deposit with the grades that caused it, which is what a student needs to understand why their
# balance moved - the second half of Tier 3 Step 3.
#
# **Nullable, and not backfilled.** Every existing row predates this, and a purchase, a sale and a fee will
# never have a grade book. Backfilling the historical earnings deposits is possible in principle - match on
# reason, portfolio and date - and deliberately not done: a guess about which quarter paid a row would be
# indistinguishable from a fact, and the only thing reading this is a difference calculation that must treat
# "unknown" as "not paid by this book".
# The index is built concurrently and the foreign key is added separately, both because
# strong_migrations asks for it: a plain index takes a write lock for as long as the build, and adding a
# validated foreign key takes one while every existing row is checked. Neither matters at this table's
# current size, and following the safe form costs nothing and keeps the pattern right for when it does.
class AddGradeBookToPortfolioTransactions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :portfolio_transactions, :grade_book, null: true,
                  index: { algorithm: :concurrently }
  end
end
