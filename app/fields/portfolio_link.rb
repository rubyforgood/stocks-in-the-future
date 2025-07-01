# frozen_string_literal: true

class PortfolioLink < Administrate::Field::Base
  def path
    data
  end
end
