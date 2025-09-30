# frozen_string_literal: true

class MonthlyPortfolioSnapshotJob < ApplicationJob
  queue_as :default

  def perform(target_date = Date.current, batch_size = 1000)
    Portfolio.includes(:portfolio_stocks, :stocks)
             .find_in_batches(batch_size: batch_size) do |batch|
      batch.each { |portfolio| create_snapshot_for_portfolio(portfolio, target_date) }
    end
  end

  private

  def create_snapshot_for_portfolio(portfolio, date)
    return if portfolio.portfolio_snapshots.exists?(date: date)

    total_value_cents = portfolio.calculate_total_value_cents

    portfolio.portfolio_snapshots.create!(
      date: date,
      worth_cents: total_value_cents
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create snapshot for portfolio #{portfolio.id}: #{e.message}"
  end
end
