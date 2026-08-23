# frozen_string_literal: true

# One row per thing a user has dismissed, replacing a column per dismissible banner.
#
# There were two - portfolios.first_share_acknowledged_at and portfolios.trading_off_dismissed_at -
# and a third would have made the pattern undeniable: every dismissible banner needs its own
# migration, its own predicate and its own route, and none of that is about the banner.
#
# On users rather than portfolios. The two it replaces lived on portfolios because both readers happen
# to be students, but a dismissal is a fact about a person, and a teacher-facing banner would
# otherwise need a third home. Portfolio still asks the questions - it is what the views have - and
# delegates to its user.
#
# A timestamp rather than a boolean, which is the part that matters: the trading-off notice compares
# it against classrooms.trading_disabled_at, so a dismissal covers the switch-off it was made against
# and not the next one. A boolean would be a mute button, and the same will be true of any recurring
# condition added later - which is why `dismissed_at` is NOT NULL rather than nullable-and-implied.
#
# The index is unique and declared inside create_table: one dismissal per user per key, and an index
# on a table being created needs no `algorithm: :concurrently` because there is nothing to lock.
class CreateDismissals < ActiveRecord::Migration[8.1]
  def up
    create_table :dismissals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.datetime :dismissed_at, null: false
      t.timestamps

      t.index %i[user_id key], unique: true
    end

    # Raw SQL, not the models: a migration has to keep working when Portfolio no longer has these
    # columns and Dismissal's validations have moved on. Only non-NULL values become rows, so a
    # student who never dismissed anything gets nothing, which is what the absence of a row means.
    #
    # safety_assured because strong_migrations cannot see inside `execute`. These are two INSERT ...
    # SELECTs into a table created moments ago in this same transaction: nothing else can be reading
    # it, there are no rows to lock, and portfolios is read-only here. The row count is bounded by the
    # number of students who have dismissed something, which is at most the number of students.
    safety_assured do
      execute(<<~SQL.squish)
        INSERT INTO dismissals (user_id, "key", dismissed_at, created_at, updated_at)
        SELECT user_id, 'first_share', first_share_acknowledged_at, NOW(), NOW()
        FROM portfolios
        WHERE first_share_acknowledged_at IS NOT NULL
      SQL

      execute(<<~SQL.squish)
        INSERT INTO dismissals (user_id, "key", dismissed_at, created_at, updated_at)
        SELECT user_id, 'trading_off', trading_off_dismissed_at, NOW(), NOW()
        FROM portfolios
        WHERE trading_off_dismissed_at IS NOT NULL
      SQL
    end
  end

  def down
    # The columns still exist at this point - they are dropped by the next migration - so rolling back
    # this one puts the data where it came from rather than discarding it.
    safety_assured do
      execute(<<~SQL.squish)
        UPDATE portfolios SET first_share_acknowledged_at = d.dismissed_at
        FROM dismissals d
        WHERE d.user_id = portfolios.user_id AND d."key" = 'first_share'
      SQL

      execute(<<~SQL.squish)
        UPDATE portfolios SET trading_off_dismissed_at = d.dismissed_at
        FROM dismissals d
        WHERE d.user_id = portfolios.user_id AND d."key" = 'trading_off'
      SQL
    end

    drop_table :dismissals
  end
end
