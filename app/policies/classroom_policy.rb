# frozen_string_literal: true

class ClassroomPolicy < ApplicationPolicy
  def index?
    user&.teacher_or_admin?
  end

  def show?
    user&.teacher_or_admin?
  end

  def new?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  # there has to be a scope class associated here
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      elsif user.teacher?
        scope.joins(:teacher_classrooms).where(teacher_classrooms: { teacher_id: user.id })
      else
        []
      end
    end
  end
end
