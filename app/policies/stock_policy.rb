# frozen_string_literal: true

class StockPolicy < ApplicationPolicy
  # Allow viewing stock pages to any authenticated user
  def show?
    true
  end

  # Show trading-related links (buy/sell/trade) when the user is a student
  # and has a portfolio (safeguard for nil portfolio) and the stock is not archived.
  def show_trading_link?
    user.present? && user.student? && portfolio_present? && !record.archived?
  end

  # Show holdings column / counts for students with a portfolio
  def show_holdings?
    user.present? && user.student? && portfolio_present?
  end

  private

  def portfolio_present?
    # Student must actually have a persisted portfolio. Nil-safe, avoids relying on cached association state.
    user&.portfolio&.persisted?
  end
end
