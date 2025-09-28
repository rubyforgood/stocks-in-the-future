# frozen_string_literal: true

class StockPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    teacher_or_admin_required? || (student_required? && !record.archived?)
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
