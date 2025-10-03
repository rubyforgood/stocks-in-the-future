# frozen_string_literal: true

class PortfolioPolicy < ApplicationPolicy
  def show?
    user.present? && record.user_id == user.id
  end

  # Add other actions as needed
end
