# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user

  GRADE_OPTIONS = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"].freeze
end
