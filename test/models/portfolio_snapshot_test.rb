# frozen_string_literal: true

require "test_helper"

class PortfolioSnapshotTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:portfolio_snapshot).validate!
  end

  test "#current_worth converts cents to dollars" do
    portfolio_snapshot = build(:portfolio_snapshot, worth_cents: 50_000)
    assert_equal 500.0, portfolio_snapshot.current_worth
  end
end
