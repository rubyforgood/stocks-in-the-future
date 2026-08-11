# frozen_string_literal: true

class Year < ApplicationRecord
  has_many :school_years, dependent: :destroy
  has_many :schools, through: :school_years
  has_many :classrooms, through: :school_years

  validates :name, presence: true, uniqueness: true

  scope :ordered_by_start_year, -> { order(Arel.sql("CAST(SUBSTRING(name FROM 1 FOR 4) AS INTEGER) DESC")) }

  # A school year runs across two calendar years, so "which one are we in" turns on the month. July is the
  # boundary: before it, we are still in the year that began last calendar year.
  #
  # The rule lives here once. It was written out inside `current_school_year` and nowhere else, and both
  # `#current?` and the window below need it - two copies of a date rule is how they come to disagree in
  # July.
  def self.current_school_year_name(date = Date.current)
    date.month <= 6 ? "#{date.year - 1} - #{date.year}" : "#{date.year} - #{date.year + 1}"
  end

  def self.current_school_year(date = Date.current)
    where(name: current_school_year_name(date))
  end

  # The years a school has not added yet, newest first. A one-at-a-time select can carry the whole list -
  # that is what a select is for - so there is no window to invent here, and no year is silently
  # unreachable. The checkbox group this replaced needed one, because it showed every option at once.
  def self.addable_to(school)
    where.not(id: school.year_ids).ordered_by_start_year
  end

  def current?
    name == self.class.current_school_year_name
  end

  def previous_year
    @previous_year || Year.find_by(name: "#{start_year_value - 1} - #{start_year_value}")
  end

  def next_year
    @next_year || Year.find_by(name: "#{end_year_value} - #{end_year_value + 1}")
  end

  private

  def start_year_value
    @start_year_value ||= parsed_year_values.first
  end

  def end_year_value
    @end_year_value ||= parsed_year_values.last
  end

  def parsed_year_values
    @parsed_year_values ||= name.split(" - ").map(&:to_i)
  end
end
