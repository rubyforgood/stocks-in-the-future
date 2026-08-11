# frozen_string_literal: true

class SchoolYear < ApplicationRecord
  belongs_to :school
  belongs_to :year
  has_many :classrooms, dependent: :restrict_with_error
  has_many :quarters, dependent: :destroy

  delegate :name, to: :school, prefix: :school
  delegate :name, to: :year, prefix: :year

  # There is a unique index on [school_id, year_id], and without this a double-submitted "Add school year"
  # is a `RecordNotUnique` rather than a message.
  validates :year_id, uniqueness: { scope: :school_id }

  after_create :create_quarters

  def name
    "#{school_name} (#{year_name})"
  end

  # **What removing this would destroy**, for a confirmation to state rather than a page to discover.
  # Creating a school year provisions four quarters, and removing it takes them with it.
  def removable?
    classrooms.none?
  end

  private

  def create_quarters
    (1..4).each do |n|
      quarters.create!(name: "Quarter #{n}", number: n)
    end
  end
end
