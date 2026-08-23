# frozen_string_literal: true

# The two per-banner columns, now that `dismissals` holds their contents. CreateDismissals ran first
# and copied every non-NULL value across, and its `down` copies them back before dropping the table,
# so this pair rolls both ways without losing a date.
#
# safety_assured, with the reason rather than as a reflex. strong_migrations blocks remove_column
# because ActiveRecord caches a table's columns at boot: on a rolling deploy, an old process still
# holding the previous schema will `SELECT` a column that no longer exists and 500 on every request
# touching it. The safe sequence is to ship `ignored_columns` first, deploy, then drop.
#
# This app deploys as a single unit rather than a rolling one, and both readers of these columns are
# removed in the same commit, so there is no window where a live process expects them. If that ever
# stops being true, the ignored_columns dance is the correct route and this migration is the wrong
# shape.
class RemoveDismissalColumnsFromPortfolios < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :portfolios, :first_share_acknowledged_at, :datetime
      remove_column :portfolios, :trading_off_dismissed_at, :datetime
    end
  end
end
