# frozen_string_literal: true

module ApplicationHelper
  def navbar_stocks
    Stock.all
  end
end
