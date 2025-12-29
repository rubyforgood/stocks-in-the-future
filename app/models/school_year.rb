# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_error
  has_many :quarters, dependent: :restrict_with_error

  def to_s
    "#{school.name} (#{year.name})"
  end
end
