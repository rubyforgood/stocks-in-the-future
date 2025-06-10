# frozen_string_literal: true

class Classroom < ApplicationRecord
  belongs_to :school_year
  has_one :school, through: :school_year
  has_one :year, through: :school_year

  has_many :users, dependent: :destroy
end
