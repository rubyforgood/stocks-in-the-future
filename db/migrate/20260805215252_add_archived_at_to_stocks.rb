# frozen_string_literal: true

# When a stock was archived, which nothing recorded: `stocks.archived` is a bare boolean, so the
# trading floor could say a company was no longer trading but never since when, and no retention
# rule could exist because there was no date to age against.
#
# Deliberately not backfilled. Existing archived stocks get NULL rather than a guess: `updated_at`
# is not the archive date (the price job touches it), and inventing a date in an app whose records
# are a child's trading history is worse than admitting the date is unknown. Stock#archived_recently
# therefore treats NULL as *in* the window - a missing date is not evidence of age, and the
# alternative silently hides rows the app shows today.
# No index. strong_migrations asks for `algorithm: :concurrently` on any add_index, which is the
# right rule for a table big enough to lock - and this one holds the handful of companies a
# classroom can trade, where a sequential scan beats an index lookup. Add one if the catalogue ever
# grows into the thousands.
class AddArchivedAtToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :archived_at, :datetime
  end
end
