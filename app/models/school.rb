# frozen_string_literal: true

class School < ApplicationRecord
  has_many :school_years
  has_many :years, through: :school_years
end
