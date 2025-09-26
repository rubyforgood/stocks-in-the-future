# frozen_string_literal: true

class PortfolioPolicy < ApplicationPolicy
  def show?
    user.present? && record.user == user
  end

  # Add other actions as needed
end
