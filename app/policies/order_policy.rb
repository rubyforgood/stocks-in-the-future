# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def create?
    user.portfolio == resource.portfolio
  end
end
