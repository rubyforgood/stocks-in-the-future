# frozen_string_literal: true

require "test_helper"

# `archived` is the flag and `archived_at` is derived from it. Two columns describing one fact is
# the drift shape, so the invariant is maintained in one callback and pinned here.
class StockArchivingTest < ActiveSupport::TestCase
  test "archiving stamps the date" do
    stock = create(:stock, archived: false)

    assert_nil stock.archived_at

    freeze_time do
      stock.update!(archived: true)

      assert_equal Time.current, stock.archived_at
    end
  end

  test "re-saving an archived stock does not move the date" do
    stock = create(:stock, archived: true)
    stamped = stock.archived_at

    travel 1.day do
      stock.update!(price_cents: 999)
    end

    assert_equal stamped.to_i, stock.reload.archived_at.to_i,
                 "the price job touches these rows constantly; the archive date must not follow"
  end

  test "un-archiving clears the date, so a second archiving reports the second date" do
    stock = create(:stock, archived: true)
    first = stock.archived_at

    stock.update!(archived: false)

    assert_nil stock.archived_at

    travel 2.days do
      stock.update!(archived: true)

      assert_operator stock.archived_at, :>, first
    end
  end

  test "archived_recently keeps a stock for the retention window and drops it after" do
    recent = create(:stock, ticker: "NEW1", archived: true)
    old = create(:stock, ticker: "OLD1", archived: true)
    old.update!(archived_at: (Stock::LIST_RETENTION + 1.day).ago)

    listed = Stock.archived_recently

    assert_includes listed, recent
    assert_not_includes listed, old
  end

  # The column was added after the fact and existing rows were deliberately not backfilled, because
  # updated_at is not the archive date and guessing one in a trading record is worse than admitting
  # it is unknown. A missing date must therefore not read as "old".
  test "a stock archived before the column existed stays listed" do
    legacy = create(:stock, ticker: "LEG1", archived: true)
    # update_column on purpose: the callback exists to stop archived_at being nil on an archived
    # stock, and a row from before the column existed is exactly that state.
    legacy.update_column(:archived_at, nil) # rubocop:disable Rails/SkipsModelValidations

    assert_includes Stock.archived_recently, legacy
  end

  test "retention is a display rule: an archived stock with history cannot be destroyed" do
    student = create(:student, :with_portfolio, classroom: create(:classroom))
    stock = create(:stock, archived: true)
    create(:portfolio_stock, portfolio: student.portfolio, stock: stock, shares: 1)

    assert_not stock.destroy, "a traded stock must not be destroyable - that is a child's history"
    assert Stock.exists?(stock.id)
  end
end
