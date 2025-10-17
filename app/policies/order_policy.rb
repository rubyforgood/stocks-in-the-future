# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.portfolio == record.portfolio
  end

  def update?
    user.portfolio == record.portfolio
  end

  def cancel?
    user.portfolio == record.portfolio
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.teacher?
        scope.for_teacher(user)
      elsif user.student?
        scope.for_student(user)
      else
        scope.none
      end
    end
  end
end
