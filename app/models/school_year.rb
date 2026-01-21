# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_exception
  has_many :quarters, dependent: :restrict_with_exception

  validates :year_id, uniqueness: { scope: :school_id, message: "already exists for this school" }

  delegate :name, to: :school, prefix: :school
  delegate :name, to: :year, prefix: :year
end
