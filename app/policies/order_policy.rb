class OrderPolicy < ApplicationPolicy
  def create?
    user.portfolio == resource.portfolio
  end
end
