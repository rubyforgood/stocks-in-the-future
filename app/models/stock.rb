# frozen_string_literal: true

class Stock < ApplicationRecord
  has_many :portfolio_stocks, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  validates :ticker, presence: true
  validates(
    :company_website,
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      allow_blank: true
    }
  )

  # `archived` stays the flag and `archived_at` is derived from it, maintained in one place below.
  # The alternative - making archived_at's presence authoritative, Discard-style - is the cleaner
  # single source of truth, but it would touch these scopes, the policy, the admin form, the seeds
  # and every test that sets `archived:`. Noted in migration.md as the tidier shape if the model is
  # ever reworked.
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  # The companies whose price moved most since yesterday, for the home page card.
  #
  # **A mover has to have moved.** Rows where the price is unchanged are excluded, not sorted to the
  # bottom, and so are rows with no yesterday price at all - which is every row until the daily price
  # job has run twice. Without that filter the card would show three companies at 0.00% and call them
  # today's movers, which is what the nav ticker it replaces did: all 18 stocks had a nil yesterday
  # price, so every item read 0.00% and, because the colour test was `>= 0`, every one read as a gain.
  #
  # Ordered in SQL rather than by loading every stock and sorting on `percentage_change` in Ruby. The
  # `* 100.0` is what keeps it out of integer division, and Postgres types it as `numeric`, so the
  # arithmetic is exact - the same reason design.md tells you not to "fix" the existing
  # `price_cents / 100.0` expressions.
  #
  # Ticker breaks the tie so the order is stable between requests when two stocks move identically.
  MOVERS_SHOWN = 3

  scope :movers, lambda { |limit = MOVERS_SHOWN|
    active
      .where.not(yesterday_price_cents: [nil, 0])
      .where("price_cents <> yesterday_price_cents")
      .order(Arel.sql("ABS((price_cents - yesterday_price_cents) * 100.0 / yesterday_price_cents) DESC"), :ticker)
      .limit(limit)
  }

  # How long an archived company stays on the student-facing list.
  #
  # This is a *display* retention rule, not a purge, and it cannot be anything else: orders.stock_id
  # and portfolio_stocks.stock_id are both NOT NULL with foreign keys, and both associations are
  # `dependent: :restrict_with_error`, so a stock a student has ever traded cannot be deleted without
  # destroying that student's trade history. The rows stay forever; the *list* is what ages.
  #
  # A school year, because that is the unit this app already thinks in - a classroom belongs to one,
  # grade books hang off its quarters - so "last year's companies" is a boundary a teacher recognises.
  LIST_RETENTION = 12.months

  # NULL counts as in-window on purpose: the column was added after the fact and existing rows were
  # not backfilled, and a missing date is not evidence of age. Hiding them would silently drop rows
  # the app shows today.
  scope :archived_recently, lambda {
    archived.where("archived_at IS NULL OR archived_at > ?", LIST_RETENTION.ago)
  }

  # One place keeps archived_at true to the flag. `||=` so re-saving an archived stock does not keep
  # moving the date forward, and clearing it on un-archive so a stock archived twice reports the
  # second date rather than the first.
  before_save :stamp_archived_at

  # Dollars, for display and for the decimal purchase_price column. price_cents
  # is the authoritative value - never convert this back into cents for
  # arithmetic or comparison, because the round trip loses value. Always render
  # through number_to_currency: interpolated raw, a whole-dollar price prints as
  # "$15.0".
  def current_price
    price_cents.to_f / 100
  end

  def yesterday_price
    return current_price if yesterday_price_cents.nil?

    yesterday_price_cents.to_f / 100
  end

  def percentage_change
    return 0.0 if yesterday_price_cents.nil? || yesterday_price_cents.zero?

    ((current_price - yesterday_price) / yesterday_price) * 100
  end

  def percentage_change_formatted
    return "0.00%" if percentage_change.zero?

    formatted = format("%.2f%%", percentage_change.abs)
    percentage_change.positive? ? "+#{formatted}" : "-#{formatted}"
  end

  private

  def stamp_archived_at
    if archived?
      self.archived_at ||= Time.current
    else
      self.archived_at = nil
    end
  end
end
