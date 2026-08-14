# frozen_string_literal: true

class StockPolicy < ApplicationPolicy
  # Show trading-related links (buy/sell/trade) when the user is a student
  # and has a portfolio (safeguard for nil portfolio) and the stock is not archived
  # (or if archived, user is holding it) and trading is enabled for their classroom.
  def show_trading_link?
    show_holdings? && (!record.archived? || user.holding?(record)) && user.classroom&.trading_open?
  end

  # Show holdings column / counts for students with a portfolio
  def show_holdings?
    user.present? && user.student? && portfolio_present?
  end

  # The staff half of the same column. `show_holdings?` answers "do you own this"; this answers "who
  # owns this, among the people you can see" - one meaning, and the viewer decides only the
  # denominator. Which classrooms count is ClassroomPolicy::Scope's job, not this one: it already
  # resolves to every classroom for an admin and to their own for a teacher, and duplicating that rule
  # here is how two definitions of one thing start.
  #
  # A teacher's trading floor was two columns before this - the buy list with the buying removed,
  # because show_holdings? requires a student with a portfolio. Nobody designed that page; it was a
  # residue. And a teacher cannot open /admin/stocks, so it was their only view of the catalogue.
  def show_class_holdings?
    user.present? && (user.teacher? || user.admin?)
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
