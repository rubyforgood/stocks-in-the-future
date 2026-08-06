# frozen_string_literal: true

# When this student closed the "trading is turned off" callout.
#
# On portfolios rather than users because the reader is always a student - a teacher sees the trading
# switch itself, not a notice about it - and because `portfolios.first_share_acknowledged_at` already
# establishes this as where a student's acknowledgements live. Two columns of the same shape in one
# table beats a second mechanism elsewhere.
#
# A timestamp rather than a boolean, and that is the whole point: it is compared against
# `classrooms.trading_disabled_at`, so the dismissal covers the switch-off it was made against and
# nothing later. A boolean here would be a mute button.
class AddTradingOffDismissedAtToPortfolios < ActiveRecord::Migration[8.1]
  def change
    add_column :portfolios, :trading_off_dismissed_at, :datetime
  end
end
