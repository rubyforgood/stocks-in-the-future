# frozen_string_literal: true

class Year < ApplicationRecord
  has_many :school_years, dependent: :destroy
  has_many :schools, through: :school_years
  has_many :classrooms, through: :school_years

  validates :name, presence: true, uniqueness: true

  scope :ordered_by_start_year, -> { order(Arel.sql("CAST(SUBSTRING(name FROM 1 FOR 4) AS INTEGER) DESC")) }

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
