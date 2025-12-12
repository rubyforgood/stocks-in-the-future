# frozen_string_literal: true

class ClassroomGrade < ApplicationRecord
  belongs_to :classroom
  belongs_to :grade

  validates :grade_id, uniqueness: { scope: :classroom_id }
end
