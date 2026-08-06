# frozen_string_literal: true

# When trading was last switched off, which nothing recorded: `classrooms.trading_enabled` is a bare
# boolean, so the app could say trading is off but not since when.
#
# This exists so the "trading is turned off" callout can be dismissed *without becoming a permanent
# mute*. A dismissal has to be relative to something, or a student who closes the message once never
# sees it again - including next term, when their teacher switches trading off for a different reason.
# With an onset timestamp, the dismissal is compared against it: dismissed after the switch hides it,
# and the next switch-off is newer than the dismissal, so it comes back.
#
# Deliberately not backfilled, for the same reason `stocks.archived_at` was not: `updated_at` is not
# the date trading changed, and a guessed date here would silently suppress a message a student is
# entitled to see. NULL means "we do not know when", and Portfolio#trading_off_notice? treats a
# dismissal as sufficient in that case - the first real toggle sets the column and the comparison
# becomes exact, so it heals itself rather than needing a backfill.
#
# No index: this is read through a classroom already loaded by id.
class AddTradingDisabledAtToClassrooms < ActiveRecord::Migration[8.1]
  def change
    add_column :classrooms, :trading_disabled_at, :datetime
  end
end
