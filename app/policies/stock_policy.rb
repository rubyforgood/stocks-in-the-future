# frozen_string_literal: true

class StockPolicy < ApplicationPolicy
  # Show trading-related links (buy/sell/trade) when the user is a student
  # and has a portfolio (safeguard for nil portfolio) and the stock is not archived.
  def show_trading_link?
    user.present? && user.student? && portfolio_present? && !record.archived?
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
      if user&.admin? || user&.teacher?
        scope.all
      else
        scope.active
      end
    end
  end
end
