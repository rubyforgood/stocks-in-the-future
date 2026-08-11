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

  # The current school year, the one before it and the one after. What a form should offer, because a school
  # being marked active in a year a decade away is not a decision anybody makes today - and the seeds create
  # current+10, so a plain descending list opened on 2036 with the useful year ten rows down.
  def self.around_current(date = Date.current)
    start = current_school_year_name(date).split(" - ").first.to_i
    where(name: ((start - 1)..(start + 1)).map { |y| "#{y} - #{y + 1}" })
  end

  # The window, **plus whatever this record already has**. Narrowing the offered set without this is data
  # loss rather than tidying: `year_ids=` replaces the whole collection, so a school linked to 2023-2024
  # would have that association destroyed by any save from a form that never showed it - along with the four
  # quarters on the `SchoolYear`, or a failure if it has classrooms, since both are `restrict_with_error`.
  # A field whose value is silently discarded looks like a save that worked.
  def self.offered_for(record, date = Date.current)
    where(id: around_current(date).ids | Array(record&.year_ids)).ordered_by_start_year
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
