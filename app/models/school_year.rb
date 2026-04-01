# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_error
  has_many :quarters, dependent: :restrict_with_error

  after_create :create_quarters

  delegate :name, to: :school, prefix: :school
  delegate :name, to: :year, prefix: :year

  def name
    "#{school_name} (#{year_name})"
  end

  private

  def create_quarters
    (1..4).each do |n|
      quarters.create!(name: "Quarter #{n}", number: n)
    end
  end
end
