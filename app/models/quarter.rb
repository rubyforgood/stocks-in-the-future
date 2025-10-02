# frozen_string_literal: true

class Quarter < ApplicationRecord
  belongs_to :school_year

  validates :number,
            presence: true,
            inclusion: { in: 1..4 },
            uniqueness: { scope: :school_year_id }

  scope :ordered, -> { order(:number) }

  def next
    return first_quarter_of_next_year if number == 4

    school_year.quarters.ordered.find_by(number: number + 1)
  end

  def previous
    return last_quarter_of_previous_year if number == 1

    school_year.quarters.ordered.find_by(number: number - 1)
  end

  private

  def first_quarter_of_next_year
    @first_quarter_of_next_year ||= begin
      next_year = school_year.year.next_year

      if next_year
        Quarter.joins(school_year: %i[school year])
               .where(
                 school_years: { school: school_year.school },
                 years: { id: next_year.id },
                 number: 1
               )
               .first
      end
    end
  end

  def last_quarter_of_previous_year
    @last_quarter_of_previous_year ||= begin
      previous_year = school_year.year.previous_year

      if previous_year
        Quarter.joins(school_year: %i[school year])
               .where(
                 school_years: { school: school_year.school },
                 years: { id: previous_year.id },
                 number: 4
               )
               .first
      end
    end
  end
end
