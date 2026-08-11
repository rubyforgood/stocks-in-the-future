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

  # Admin only, and the same test as `finalize?` on purpose: reopening a paid book is the other half of
  # releasing the money, so whoever is trusted with one is trusted with the other. A teacher who spots a
  # mistake asks; that is the point of the door existing rather than the endpoint simply accepting writes,
  # which is what it did before.
  def reopen?
    finalize?
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
