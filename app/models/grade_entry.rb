# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  validates :days_missed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
