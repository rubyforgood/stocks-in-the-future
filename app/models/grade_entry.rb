# frozen_string_literal: true

class GradeEntry < ApplicationRecord
  belongs_to :grade_book
  belongs_to :user
end
