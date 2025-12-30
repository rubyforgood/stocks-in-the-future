# frozen_string_literal: true

class PortfolioPolicy < ApplicationPolicy
  def show?
    return false if user.blank?
    return true if user.admin?
    return true if record.user_id == user.id

    user.teacher? && teacher_access?
  end

  private

  def teacher_access?
    teacher_ids = record.user&.classroom&.teacher_ids
    teacher_ids&.include?(user.id)
  end
end
