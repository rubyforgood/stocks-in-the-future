# frozen_string_literal: true

class PortfolioPolicy < ApplicationPolicy
  def show?
    return true if user&.admin?
    return true if user&.teacher? && user.classroom_ids.include?(record.user.classroom_id)

    user.present? && record.user_id == user.id
  end

  # Add other actions as needed
end
