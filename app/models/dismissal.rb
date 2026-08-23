# frozen_string_literal: true

# A thing a user has dismissed, and when.
#
# The keys are an explicit list rather than free text, for two reasons. It is what the controller
# checks a request against, so a client cannot write arbitrary rows into this table. And a typo in a
# view - `dismissed?("trading-off")` against a row saying `trading_off` - would otherwise be a banner
# that silently never dismisses, which is the kind of bug that gets reported as "the button does
# nothing".
class Dismissal < ApplicationRecord
  FIRST_SHARE = "first_share"
  TRADING_OFF = "trading_off"
  KEYS = [FIRST_SHARE, TRADING_OFF].freeze

  belongs_to :user

  validates :key, presence: true, inclusion: { in: KEYS }
  validates :dismissed_at, presence: true
  validates :user_id, uniqueness: { scope: :key }
end
