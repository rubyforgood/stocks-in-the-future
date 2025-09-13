# frozen_string_literal: true

class Quarter < ApplicationRecord
  belongs_to :school_year

  validates :number,
            presence: true,
            inclusion: { in: 1..4 },
            uniqueness: { scope: :school_year_id }

  scope :ordered, -> { order(:number) }

  def next
    school_year.quarters.ordered.find_by(number: number + 1)
  end

  def previous
    school_year.quarters.ordered.find_by(number: number - 1)
  end
end
