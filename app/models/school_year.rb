# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_error
  has_many :quarters, dependent: :destroy

  delegate :name, to: :school, prefix: :school
  delegate :name, to: :year, prefix: :year

  after_create :create_quarters

  # So the admin form can set each quarter's teaching days - the denominator perfect attendance is
  # derived from. Without a way to enter it the derivation could never switch on, and a feature that can
  # only report that it did nothing is the shape this codebase keeps removing.
  accepts_nested_attributes_for :quarters

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
