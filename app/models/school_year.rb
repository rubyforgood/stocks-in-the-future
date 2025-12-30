# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_error
  has_many :quarters, dependent: :restrict_with_error

  delegate :name, to: :school, prefix: true
  delegate :name, to: :year, prefix: true

  def to_s
    "#{school_name} (#{year_name})"
  end
end
