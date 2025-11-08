# frozen_string_literal: true

class StockPolicy < ApplicationPolicy
  # Show trading-related links (buy/sell/trade) when the user is a student
  # and has a portfolio (safeguard for nil portfolio) and the stock is not archived
  # (or if archived, user is holding it) and trading is enabled for their classroom.
  def show_trading_link?
    show_holdings? && (!record.archived? || user.holding?(record)) && user.classroom&.trading_enabled?
  end

  # Show holdings column / counts for students with a portfolio
  def show_holdings?
    user.present? && user.student? && portfolio_present?
  end

  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def new?
    create?
  end

  def create?
    admin_required?
  end

  def edit?
    update?
  end

  def update?
    admin_required?
  end

  def destroy?
    admin_required?
  end

  private

  def portfolio_present?
    # Student must actually have a persisted portfolio. Nil-safe, avoids relying on cached association state.
    user&.portfolio&.persisted?
  end

  # Scope to control which stocks are visible in listings
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
