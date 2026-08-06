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

  # A teacher may edit a classroom they teach. Same rule as toggle_trading? below, which a teacher
  # has always had - being trusted to open and close trading but not to correct a typo in the name
  # was the inconsistency.
  #
  # **What they may change is narrower than what an admin may**, and that lives in
  # permitted_attributes rather than in the controller: the edit form also carries school, year and
  # the teacher assignment, and those are not a classroom's own settings. A teacher who could set
  # teacher_ids could grant another teacher access to their classroom, or remove themselves from it
  # and lose the classroom entirely - neither is a teaching action.
  def update?
    return true if user.admin?
    return false unless user.teacher?

    teacher_of_record?
  end

  # Delegating rather than repeating the rule. These were two separate `user.admin?` bodies, which is
  # the shape that lets a viewer be shown an Edit link and then refused on submit.
  def edit?
    update?
  end

  def create?
    user.admin?
  end

  # Everything a classroom has; only an admin gets the last three.
  #
  # `school_id` and `year_id` move the classroom to a different school year, and `teacher_ids` is who
  # may see and edit it. `grade_ids` and `trading_enabled` are how the class is taught, so they stay.
  ADMIN_ATTRIBUTES = [:name, :trading_enabled, :school_id, :year_id,
                      { grade_ids: [] }, { teacher_ids: [] }].freeze
  TEACHER_ATTRIBUTES = [:name, :trading_enabled, { grade_ids: [] }].freeze

  def permitted_attributes
    user.admin? ? ADMIN_ATTRIBUTES : TEACHER_ATTRIBUTES
  end

  def toggle_archive?
    user.admin?
  end

  def toggle_trading?
    return true if user.admin?
    return false unless user.teacher?

    teacher_of_record?
  end

  private

  # `record` is a Classroom instance for every action that asks this, but a policy can also be built
  # around the class - `policy(Classroom).new?` in the index view - so this refuses rather than raising
  # NoMethodError on Class#id if one of those ever starts calling it.
  def teacher_of_record?
    return false unless record.is_a?(Classroom)

    user.classroom_ids.include?(record.id)
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
        scope.active.joins(:teacher_classrooms).where(teacher_classrooms: { teacher_id: user.id })
      else
        []
      end
    end
  end
end
