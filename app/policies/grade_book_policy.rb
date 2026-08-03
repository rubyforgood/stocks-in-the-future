# frozen_string_literal: true

class GradeBookPolicy < ApplicationPolicy
  def update?
    user_is_teacher_of_classroom? || user.admin?
  end

  def show?
    user_is_teacher_of_classroom? || user.admin?
  end

  def finalize?
    user.admin?
  end

  # Whoever may enter grades may create the rows to enter them into.
  def populate?
    update?
  end

  private

  def user_is_teacher_of_classroom?
    user.teacher? && record.classroom.teachers.include?(user)
  end
end
