# frozen_string_literal: true

require "test_helper"

class MonthlyPortfolioSnapshotJobTest < ActiveJob::TestCase
  setup do
    @user = create(:student)
    @portfolio = @user.portfolio
    @target_date = Date.new(2024, 12, 1)
  end

  test "creates snapshot calculating cash and stock holdings" do
    create(:portfolio_transaction, :deposit, portfolio: @portfolio, amount_cents: 50_000)
    stock = create(:stock, price_cents: 10_000)
    create(:portfolio_stock, portfolio: @portfolio, stock: stock, shares: 10)

    assert_difference("PortfolioSnapshot.count", 1) do
      MonthlyPortfolioSnapshotJob.perform_now(@target_date)
    end

    snapshot = @portfolio.portfolio_snapshots.find_by(date: @target_date)
    expected_value = @portfolio.calculate_total_value_cents
    assert_equal expected_value, snapshot.worth_cents
  end

  test "handles empty portfolio database" do
    Portfolio.delete_all

    assert_no_difference("PortfolioSnapshot.count") do
      MonthlyPortfolioSnapshotJob.perform_now(@target_date)
    end
  end

  test "skips existing snapshots" do
    create(:portfolio_snapshot, portfolio: @portfolio, date: @target_date)

    assert_no_difference("PortfolioSnapshot.count") do
      MonthlyPortfolioSnapshotJob.perform_now(@target_date)
    end
  end
end
