# frozen_string_literal: true

module ApplicationHelper
  def navbar_stocks
    Stock.all
  end

  def current_portfolio
    current_user&.portfolio&.id
  end
end
