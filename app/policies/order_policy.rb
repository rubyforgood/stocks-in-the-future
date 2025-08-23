# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def create?
    user.portfolio == record.portfolio
  end

  def update?
    user.portfolio == record.portfolio
  end

  def cancel?
    user.portfolio == record.portfolio
  end
end
